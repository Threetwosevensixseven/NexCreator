using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media.Imaging;

namespace SpectronPaletteSampler
{
    class Program
    {
        static void Main(string[] args)
        {
            //Sample("LastFamily-Border", @"video\last-family-small.gif", 7, 16);
            //Sample("LastFamily-Text", @"video\last-family-small.gif", 102, 29);
            //Sample("Inspired-Title", @"video\inspired-small.gif", 102, 29);
            //Sample("Inspired-Para1", @"video\inspired-small.gif", 35, 49);
            //Sample("Inspired-Para2", @"video\inspired-small.gif", 34, 93);
            //Sample("Title-Presented", @"video\title-full.gif", 351, 482);
            //Sample("Title-Copyright", @"video\title-full.gif", 199, 581);
            //Sample("Grunts-Title", @"video\grunts-small.gif", 102, 29);
            //Sample("Grunts-Para1", @"video\grunts-small.gif", 37, 84);
            //Sample("Hulks-Para1", @"video\hulks-small.gif", 56, 82);
            //Sample("Hulks-SkullEye", @"video\hulks-small.gif", 74, 187);
            //Sample("Spheroids-Title", @"video\spheroids-small.gif", 103, 29);
            //Sample("Spheroids-Border", @"video\spheroids-small.gif", 7, 15);
            //Sample("Spheroids-Para1", @"video\spheroids-small.gif", 37, 108);
            //Sample("Brains-Title", @"video\brains-small.gif", 103, 29);
            //Sample("Brains-Border", @"video\brains-small.gif", 7, 15);
            //Sample("Brains-Para1", @"video\brains-small.gif", 35, 85);
            //Sample("Brains-Credits", @"video\brains-small.gif", 124, 232);
            //Sample("Electrons-ElectronA", @"video\electrons-small-a.gif", 206, 191);
            //Sample("Electrons-ElectronB", @"video\electrons-small-a.gif", 223, 187);
            //Sample("Electrons-ElectronC", @"video\electrons-small-a.gif", 245, 188);
            //Sample("Electrons-ElectronD", @"video\electrons-small-a.gif", 266, 194);
            //Sample("Electrodes-Title   ", @"video\electrons-small-a.gif", 103, 029);
            //Sample("Electrodes-Para1   ", @"video\electrons-small-a.gif", 035, 093);
            //Sample("Electrodes-Border  ", @"video\electrons-small-a.gif", 007, 015);
            //Sample("Electrodes-Credits ", @"video\electrons-small-a.gif", 124, 232);
            Sample("Electrodes-Credits ", @"C:\Users\robin\Documents\Visual Studio 2015\Projects\NexCreator\scr\layer2.bmp", 0, 0);
        }

        #region Helpers

        public const string MAGENTA = "ff00ff";
        public const string MAGENTA_ALT = "ff24ff";

        public static void Sample(string ResultsFileName, string GifFileName, int X, int Y)
        {
            var sb = new StringBuilder();
            string path = Path.GetDirectoryName(new Uri(Assembly.GetExecutingAssembly().CodeBase).LocalPath);
            string inFile = Path.Combine(path, "..", "..", "..", "..", GifFileName);
            string outFile = Path.Combine(path, "Data");
            if (!Directory.Exists(outFile))
                Directory.CreateDirectory(outFile);
            outFile = Path.Combine(outFile, (ResultsFileName ?? "").Trim() + ".txt");

            var imageStreamSource = new FileStream(inFile, FileMode.Open, FileAccess.Read, FileShare.Read);
            //var decoder = new GifBitmapDecoder(imageStreamSource, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.Default);
            var decoder = new BmpBitmapDecoder(imageStreamSource, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.Default);
            var palette = decoder.Palette;

            using (var img = Bitmap.FromFile(inFile, true) as Bitmap)
            {
                FrameDimension dimension = new FrameDimension(img.FrameDimensionsList[0]);
                int frameCount = img.GetFrameCount(dimension);
                for (int i = 0; i < frameCount; i++)
                {
                    img.SelectActiveFrame(dimension, i);
                    var col = img.GetPixel(X, Y);
                    sb.AppendLine(GetRRGGBB(col));
                }
            }
            File.WriteAllText(outFile, sb.ToString());
        }

        public static string GetRRGGBB(Color Colour)
        {
            var val = Colour.R.ToString("x2")
            + Colour.G.ToString("x2")
            + Colour.B.ToString("x2");
            if (val == MAGENTA)
                return MAGENTA_ALT;
            return val;
        }

        #endregion Helpers
    }
}
