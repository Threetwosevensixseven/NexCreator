using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GenerateMMUBanks
{
    public class Program
    {
        private static void Main(string[] args)
        {
            for (byte bank16 = 8; bank16 <= 111; bank16++)
            {
                var bytes = Enumerable.Repeat(Convert.ToByte(bank16 * 2), 0x2000)
                    .Concat(Enumerable.Repeat(Convert.ToByte((bank16 * 2) + 1), 0x2000))
                    .ToArray();
                string fn = Path.Combine(BankDirectory, "Bank" + bank16 + ".bin");
                File.WriteAllBytes(fn, bytes);
            }
            for (byte bank8 = 16; bank8 <= 223; bank8++)
            {
                var bytes = Enumerable.Repeat(bank8, 0x2000).ToArray();
                string fn = Path.Combine(BankDirectory, "mmu" + bank8 + ".bin");
                File.WriteAllBytes(fn, bytes);
            }
        }

        private static string BankDirectory
        {
            get
            {
                return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "nex");
            }
        }
    }
}
