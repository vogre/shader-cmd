import std.stdio;
import std.conv;
import std.string;
import std.range;
import derelict.freeimage.freeimage;

class ImageData
{
    ubyte[] data;
    int rows;
    int cols;
    int channels;

    this(ubyte[] _data, int _rows, int _cols, int _channels)
    {
        data = _data;
        rows = _rows;
        cols = _cols;
        channels = _channels;
    }
}

ImageData load_image(string filename)
{
    auto format = FreeImage_GetFileType(filename.toStringz(), 0);
    if (format == FIF_UNKNOWN)
        throw new Exception("Could not determine file type");
    writeln("Format "~to!string(format));
    auto im = FreeImage_Load(format, filename.ptr);
    if (!im)
        throw new Exception("Could not load image");
    scope(exit)
        FreeImage_Unload(im);
    if (!FreeImage_HasPixels(im))
        throw new Exception("Header only image");
    auto imtype = FreeImage_GetImageType(im);
    writeln("Image type ", imtype);
    auto bpp = FreeImage_GetBPP(im), bspp = bpp/8;
    if (bspp!=3 && bspp!=4)
        throw new Exception("Unsupported image type");
    writeln("Image bpp ", bpp);
    auto rows = FreeImage_GetHeight(im), cols = FreeImage_GetWidth(im);
    auto pitch = FreeImage_GetPitch(im);
    auto res = new ubyte[rows*pitch];
    auto bits = FreeImage_GetBits(im);
    res[0..rows*pitch] = bits[0..rows*pitch];
    return new ImageData(res, rows, cols, bspp);
}

