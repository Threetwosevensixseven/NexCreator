#include "stdio.h"
#include "stdlib.h"

FILE *fin1;
FILE *fin2;
FILE *fout;
int line = 0;
int filecount = 0;
unsigned char *ptr = NULL;
int bank = 0;
int lastBank = -1;
int address = 0;
long long filelen;
int fileadded = 0;
int palcnt;

#define CORE_MAJOR		0
#define CORE_MINOR		1
#define CORE_SUBMINOR	2

typedef struct {
    unsigned char Next[4];			//"Next"
    unsigned char VersionNumber[4];	//"V1.0"
    unsigned char RAM_Required;		//0=768K, 1=1792K
    unsigned char NumBanksToLoad;	//0-112 x 16K banks
    unsigned char LoadingScreen;	//1 = layer2 at 16K page 9, 2=ULA loading, 4=LORES, 8=HiRes, 16=HIColour, +128 = don't load palette.
    unsigned char BorderColour;		//0-7 ld a,BorderColour:out(254),a
    unsigned short SP;				//Stack Pointer
    unsigned short PC;				//Code Entry Point : $0000 = Don't run just load.
    unsigned short NumExtraFiles;	//NumExtraFiles
    unsigned char Banks[64 + 48];		//Which 16K Banks load.	: Bank 5 = $0000-$3fff, Bank 2 = $4000-$7fff, Bank 0 = $c000-$ffff
    unsigned char loadingBar;		//Loading bar off=0/on=1
    unsigned char loadingColour;	//Loading bar Layer2 index colour
    unsigned char loadingBankDelay;	//Delay after each bank
    unsigned char loadedDelay;		//Delay (frames) after loading before running
    unsigned char dontResetRegs;	//Don't reset the registers
    unsigned char CoreRequired[3];	//CoreRequired byte per value, decimal, not string. ordering... Major, Minor, Subminor
    unsigned char HiResColours;		//to be anded with three, and shifted left three times, and add the mode number for hires and out (255),a
    unsigned char RestOf512Bytes[512 - (4 + 4 + 1 + 1 + 1 + 1 + 2 + 2 + 2 + 64 + 48 + 1 + 1 + 1 + 1 + 1 + 3 + 1)];
}HEADER;
HEADER header512 = {
    "Next",
    "V1.1",
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    { 0 },
    0,
    0,
    0,
    0,
    0,
    { 0,0,0 },
    { 0 }
};

typedef struct {
    unsigned char filename[64 - 8];
    unsigned int offset;
    unsigned int length;
}EXTRAFILE;
EXTRAFILE extrafiles[65536];		// enough room for 65536 extra files

unsigned char tempHeader[0x36];
unsigned char tempPalette[256 * 4];

unsigned char dontSavePalette = 0;

unsigned short palette[256];
unsigned char loading[49152];
unsigned char loadingULA[6144 + 768 + 256];
unsigned short paletteLoRes[256];
unsigned char loadingLoRes[6144 + 6144];
unsigned char loadingHiRes[6144 + 6144 + 768 + 256];
unsigned char loadingHiCol[6144 + 6144];

int HiResColour = 0;

unsigned char bigFile[224 * 0x4000];
unsigned char temp16k[16384];
unsigned char inputLine[4096];
unsigned char filename[1024];

unsigned char SNAHeader[27];
unsigned char SNA128Header[4] = { 0,0,0,0 };

void skipSpace()
{
    while (ptr[0] == ' ')
    {
        ptr++;
    }
}

void getString(char *dst, int maxlen)
{
    int i = 0;
    skipSpace();
    while (i<(maxlen - 2) && *ptr != ',' && *ptr != 0)
    {
        dst[i++] = *ptr++;
    }
    dst[i] = 0;
}

int getInt()
{
    int i = 0;
    skipSpace();
    if (ptr[0] == '$')
    {
        ptr++;
        return getHex();
    }
    while (*ptr != ',' && *ptr != 0)
    {
        if (*ptr<'0' || *ptr>'9') return 0;
        i = i * 10 + (*ptr++) - '0';
    }
    return i;
}

int getHex()
{
    int i = 0;
    skipSpace();
    while (*ptr != ',' && *ptr != 0)
    {
        if (*ptr >= '0' && *ptr <= '9')
            i = i * 16 + (*ptr++) - '0';
        else if (*ptr >= 'a' && *ptr <= 'f')
            i = i * 16 + (*ptr++) - ('a' - 10);
        else if (*ptr >= 'A' && *ptr <= 'F')
            i = i * 16 + (*ptr++) - ('A' - 10);
        else return 0;
    }
    return i;
}

// we're ignoring bank at $c000 initially being variable and keeping it as 0 as we're creating a large SNA not saving one mid game.
//			      0,1,2,3,4,5,6,7
int bankAdjust[] = { 2,3,1,4,5,0,6,7 };

int getRealBank(int bnk)
{
    if (bnk>7) return bnk;
    return bankAdjust[bnk];
}

int bankOrder[] = { 5,2,0,1,3,4,6,7 };
int getBankOrder(int bnk)
{
    if (bnk>7) return bnk;
    return bankOrder[bnk];
}

// we're ignoring bank at $c000 initially being variable and keeping it as 0 as we're creating a large SNA not saving one mid game.
//		        0,1,2,3,4,5,6,7
int nextBank[] = { 1,3,0,4,6,2,7,8 };
int getNextBank(int bnk)
{
    if (bnk>7) return bnk + 1;
    return nextBank[bnk];
}

void addFile(char *fname)
{
    if (strlen(fname)<3) return;
    fin2 = fopen(fname, "rb");
    if (fin2 == NULL)
    {
        printf("Can't open '%s'\n", fname);
        return;
    }
    int sna = 0;
    if ((fname[strlen(fname) - 3] & 0xdf) == 'S')
    {
        if ((fname[strlen(fname) - 2] & 0xdf) == 'N')
        {
            if ((fname[strlen(fname) - 1] & 0xdf) == 'A')
            {
                fread(SNAHeader, 1, 27, fin2);
                bank = 5;
                address = 0x4000;
                sna = 1;
            }
        }
    }
    while (!feof(fin2))
    {
        int realBank = getRealBank(bank);
        long len = fread(&bigFile[realBank * 16384 + (address & 0x3fff)], 1, 0x4000 - (address & 0x3fff), fin2);
        if (len == 0) continue;
        if (bank<64 + 48)
        {
            header512.Banks[bank] = 1;
        }
        printf("bank=%d,addr=%04x,realbank=%d,%d\n", bank, address, realBank, len);
        if (realBank>lastBank) lastBank = realBank;
        if (sna == 1)
        {
            if (bank == 0)
            {
                len = fread(&SNA128Header, 1, 4, fin2);
                printf("128KHeader len = %d\n", len);
                int sp = (SNAHeader[23] + 256 * SNAHeader[24]);
                if (len == 0)
                {
                    int sp2 = sp;
                    if (sp2 >= 16384) sp2 -= 16384;
                    SNA128Header[0] = bigFile[sp2 + 16];
                    SNA128Header[1] = bigFile[sp2 + 17];
                    SNA128Header[2] = 0;
                    SNA128Header[3] = 0;
                }
                header512.SP = sp;
                header512.PC = SNA128Header[0] + 256 * SNA128Header[1];
                printf("SP=%04x,PC=%04x\n", header512.SP, header512.PC);
            }
        }
        address = ((address & 0xc000) + 0x4000) & 0xc000;
        bank = getNextBank(bank);
    }
    fclose(fin2);
}

int use8BitPalette = 0;
unsigned char convert8BitTo3Bits(unsigned char v)
{
    int ret = v;//+16;
    if (ret>255) ret = 255;
    ret = ret >> 5;
    return ret;
}

int main(int c, char **s)
{
    int i, j;
    if (c != 3)
    {
        printf("Nex File Creator\nUsage :- \nNexCreator source.txt dest.big\n\n");
        return(1);
    }
    fin1 = fopen(s[1], "rt");
    if (fin1 == NULL)
    {
        printf("Can't open '%s'\n", s[1]);
        return(1);
    }
    line = 0;
    filecount = 0;
    bank = 0;
    address = 0;
    while (!feof(fin1))
    {
        memset(inputLine, 0, sizeof(inputLine));
        fgets(inputLine, sizeof(inputLine), fin1);
        if (strlen(inputLine)>0)
        {
            if (inputLine[strlen(inputLine) - 1] == 10)	inputLine[strlen(inputLine) - 1] = 0;
            if (strlen(inputLine)>0)
            {
                if (inputLine[strlen(inputLine) - 1] == 13)	inputLine[strlen(inputLine) - 1] = 0;
            }
        }
        line++;
        if (inputLine[0] == '!')
        {
            if (((inputLine[1] & 0xdf) == 'C') && ((inputLine[2] & 0xdf) == 'O') && ((inputLine[3] & 0xdf) == 'R'))
            {
                ptr = &inputLine[4];
                header512.CoreRequired[CORE_MAJOR] = getInt();		//Loading bar off=0/on=1
                if (ptr[0] == ',')
                {
                    ptr++;
                    header512.CoreRequired[CORE_MINOR] = getInt();	//Loading bar Layer2 index colour
                    if (ptr[0] == ',')
                    {
                        ptr++;
                        header512.CoreRequired[CORE_SUBMINOR] = getInt();	//Delay after each bank
                    }
                }
                printf("Requires Core %d,%d,%d or greater\n", header512.CoreRequired[CORE_MAJOR], header512.CoreRequired[CORE_MINOR], header512.CoreRequired[CORE_SUBMINOR]);
            }
            else if (((inputLine[1] & 0xdf) == 'B') && ((inputLine[2] & 0xdf) == 'M') && ((inputLine[3] & 0xdf) == 'P'))
            {
                ptr = &inputLine[4];
                skipSpace();
                if (ptr[0] == '!')
                {
                    ptr++;
                    dontSavePalette = 1;
                }
                if (ptr[0] == '8')
                {
                    ptr++;
                    use8BitPalette = 1;
                    if (ptr[0] == ',')
                    {
                        ptr++;
                    }
                }
                getString(filename, sizeof(filename));
                if (ptr[0] == ',')
                {
                    ptr++;
                    header512.BorderColour = getInt();
                }
                fin2 = fopen(filename, "rb");
                if (fin2 != NULL)
                {
                    fread(tempHeader, 1, 0x36, fin2);
                    fread(tempPalette, 4, 256, fin2);
                    for (i = 0; i<256; i++)
                    {
                        palette[i] = ((convert8BitTo3Bits(tempPalette[i * 4 + 0]) >> 2 & 1) << 8) + (convert8BitTo3Bits(tempPalette[i * 4 + 0]) >> 1) + (convert8BitTo3Bits(tempPalette[i * 4 + 1]) << 2) + (convert8BitTo3Bits(tempPalette[i * 4 + 2]) << 5);
                        if (use8BitPalette != 0)	palette[i] &= 255;
                    }
                    i = tempHeader[11] * 256 + tempHeader[10];
                    fseek(fin2, (long int)i, SEEK_SET);
                    for (i = 0; i<192; i++)
                    {
                        if (tempHeader[25]<128)
                        {
                            fread(&loading[(191 - i) * 256], 1, 256, fin2);
                        }
                        else
                        {
                            fread(&loading[i * 256], 1, 256, fin2);
                        }
                    }
                    fclose(fin2);
                    header512.LoadingScreen |= 1 + (dontSavePalette ? 128 : 0);
                    printf("Loading Screen '%s'\n", filename);
                    fileadded = 1;
                    if (ptr[0] == ',')
                    {
                        ptr++;
                        header512.loadingBar = getInt();		//Loading bar off=0/on=1
                        if (ptr[0] == ',')
                        {
                            ptr++;
                            header512.loadingColour = getInt();	//Loading bar Layer2 index colour
                            if (ptr[0] == ',')
                            {
                                ptr++;
                                header512.loadingBankDelay = getInt();	//Delay after each bank
                                if (ptr[0] == ',')
                                {
                                    ptr++;
                                    header512.loadedDelay = getInt();		//Delay (frames) after loading before running
                                }
                            }
                        }
                    }
                }
                if (ptr[0] == ',')
                {
                    HiResColour = getInt();
                }
            }
            else if (((inputLine[1] & 0xdf) == 'S') && ((inputLine[2] & 0xdf) == 'C') && ((inputLine[3] & 0xdf) == 'R'))
            {
                ptr = &inputLine[4];
                getString(filename, sizeof(filename));
                fin2 = fopen(filename, "rb");
                if (fin2 != NULL)
                {
                    fread(&loadingULA[0], 1, 6144 + 768, fin2);
                    fclose(fin2);
                    header512.LoadingScreen |= 2;
                    printf("Loading Screen '%s'\n", filename);
                    fileadded = 1;
                }
                else
                {
                    printf("Can't find '%s'\n", filename);
                }
            }
            else if (((inputLine[1] & 0xdf) == 'S') && ((inputLine[2] & 0xdf) == 'L') && ((inputLine[3] & 0xdf) == 'R'))
            {
                ptr = &inputLine[4];
                getString(filename, sizeof(filename));
                fin2 = fopen(filename, "rb");
                if (fin2 != NULL)
                {
                    fread(tempHeader, 1, 0x36, fin2);
                    fread(tempPalette, 4, 256, fin2);
                    for (i = 0; i<256; i++)
                    {
                        paletteLoRes[i] = ((convert8BitTo3Bits(tempPalette[i * 4 + 0]) >> 2 & 1) << 8) + (convert8BitTo3Bits(tempPalette[i * 4 + 0]) >> 1) + (convert8BitTo3Bits(tempPalette[i * 4 + 1]) << 2) + (convert8BitTo3Bits(tempPalette[i * 4 + 2]) << 5);
                    }
                    i = tempHeader[11] * 256 + tempHeader[10];
                    fseek(fin2, (long int)i, SEEK_SET);
                    for (i = 0; i<96; i++)
                    {
                        if (tempHeader[25]<128)
                        {
                            fread(&loadingLoRes[(95 - i) * 128], 1, 128, fin2);
                        }
                        else
                        {
                            fread(&loadingLoRes[i * 128], 1, 128, fin2);
                        }
                    }
                    fclose(fin2);
                    header512.LoadingScreen |= 4;
                    printf("Loading Screen '%s'\n", filename);
                    fileadded = 1;
                }
                else
                {
                    printf("Can't find '%s'\n", filename);
                }
            }
            else if (((inputLine[1] & 0xdf) == 'S') && ((inputLine[2] & 0xdf) == 'H') && ((inputLine[3] & 0xdf) == 'R'))
            {
                ptr = &inputLine[4];
                getString(filename, sizeof(filename));
                fin2 = fopen(filename, "rb");
                if (fin2 != NULL)
                {
                    fread(&loadingHiRes[0], 1, 6144 + 6144, fin2);
                    fclose(fin2);
                    header512.LoadingScreen |= 8;
                    printf("Loading Screen '%s'\n", filename);
                    fileadded = 1;
                    if (ptr[0] == ',')
                    {
                        header512.HiResColours = getInt();
                    }
                }
                else
                {
                    printf("Can't find '%s'\n", filename);
                }
            }
            else if (((inputLine[1] & 0xdf) == 'S') && ((inputLine[2] & 0xdf) == 'H') && ((inputLine[3] & 0xdf) == 'C'))
            {
                ptr = &inputLine[4];
                getString(filename, sizeof(filename));
                fin2 = fopen(filename, "rb");
                if (fin2 != NULL)
                {
                    fread(&loadingHiCol[0], 1, 6144 + 6144, fin2);
                    fclose(fin2);
                    header512.LoadingScreen |= 16;
                    printf("Loading Screen '%s'\n", filename);
                    fileadded = 1;
                }
            }
        }
        else if (inputLine[0] != ';' && inputLine[0] != 0)
        {
            ptr = inputLine;
            getString(filename, sizeof(filename));
            if (ptr[0] == ',')
            {
                ptr++;
                bank = getInt();
                if (ptr[0] == ',')
                {
                    ptr++;
                    address = getHex();
                }
            }
            printf("File '%s' %d, %04x\n", filename, bank, address);
            addFile(filename);
        }
        //		printf("line %d='%s'\n",line,inputLine);
    }
    fclose(fin1);
    if ((lastBank>-1) || (fileadded != 0))
    {
        for (i = 0; i < 64 + 48; i++)
        {
            if (header512.Banks[i] > 0) header512.NumBanksToLoad++;
            if (i >= 48) header512.RAM_Required = 1;
        }
        fout = fopen(s[2], "wb");
        if (fout == NULL)
        {
            printf("Can't open '%s'\n", s[2]);
            return(1);
        }
        fwrite(&header512, 1, 512, fout);
        if (header512.LoadingScreen)
        {
            if (header512.LoadingScreen & 1)
            {
                if (!(header512.LoadingScreen & 128))	fwrite(palette, 2, 256, fout);
                fwrite(loading, 256, 192, fout);
            }
            if (header512.LoadingScreen & 2)
            {
                fwrite(loadingULA, 1, 6144 + 768 + 256, fout);
            }
            if (header512.LoadingScreen & 4)
            {
                if (!(header512.LoadingScreen & 128))	fwrite(paletteLoRes, 2, 256, fout);
                fwrite(loadingLoRes, 1, 6144 + 6144, fout);
            }
            if (header512.LoadingScreen & 8)
            {
                fwrite(loadingHiRes, 1, 6144 + 6144, fout);
            }
            if (header512.LoadingScreen & 16)
            {
                fwrite(loadingHiCol, 1, 6144 + 6144, fout);
            }
        }
        for (i = 0; i<112; i++)
        {
            if (header512.Banks[getBankOrder(i)])
            {
                fwrite(&bigFile[i * 16384], 1, 16384, fout);
            }
        }
        fclose(fout);
    }
}