package img_tin

import "core:fmt"


generate_ppm_data :: proc(image: Image, data: ^Data){

    append(&data.buf, u8('P'), u8('6'), u8('\n')); // PPM identifier, binary-P6, ascii-P3
    // resolution of the image
    for char in fmt.tprint(image.width, image.height, "\n") {
        append(&data.buf, u8(char));
    }
    append(&data.buf, u8('2'), u8('5'), u8('5'), u8('\n')); // max color value
    // write image data
    for y in 0..<image.height {
        for x in 0..<image.width{
            color := get_pixel(x, y, image);
            rgba: [4]u8 = transmute([4]u8)color;
            append(&data.buf, rgba[0], rgba[1], rgba[2]);
        }
    }
}
