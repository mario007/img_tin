package img_tin

import "core:mem"
import "core:os"
import "core:path"

import "core:fmt"

// Note: (x:=0, y:=0) - represent left-top corner of the image
Image :: struct {
    width, height: u32,
    pixels: rawptr,
};

create_image :: proc (width, height: u32)  -> Image {
    pixels: rawptr = mem.alloc(int(width * height * 4), 16);
    return Image{width, height, pixels};
}

free_image :: proc(image: Image) {
    mem.free(image.pixels);
}

color :: inline proc(r, g, b, a: u8) -> u32 {
    return u32(r)<<24 | u32(g)<<16 | u32(b)<<8 | u32(a);
}

set_pixel :: proc (x, y: u32, image: Image, color: u32) {
    address := uintptr(image.pixels) + uintptr(y * image.width * 4 + x * 4);
    (^u32)(address)^ = color;
}

get_pixel :: proc(x, y: u32, image: Image) -> u32 {
    address := uintptr(image.pixels) + uintptr(y * image.width * 4 + x * 4);
    return (^u32)(address)^;
}

draw_rect :: proc(x1, y1, x2, y2: u32, image: Image, color: u32){
    for y in y1..<y2 {
        for x in x1..<x2{
            set_pixel(x, y, image, color);
        }
    }
}


Encoder :: enum{PPM, TGA};

Data :: struct{
    buf: [dynamic]byte,
};

write_img_to_file :: proc(file_path: string, image: Image, encoder: Encoder) -> (success: bool){

    data := Data{buf=make([dynamic]byte)};
    defer delete(data.buf);

    switch encoder {
        case Encoder.PPM:
            generate_ppm_data(image, &data);
        case Encoder.TGA:
            generate_tga_data(image, &data);
    }

    return os.write_entire_file (file_path, data.buf[:]);
}

load_image_from_file :: proc(file_path: string) -> (Image, bool, string) {

    err := "";
    image : Image;

    data, success := os.read_entire_file(file_path);
    defer delete(data);

    if !success {
        return image, success, "Cannot read file!";
    }

    switch ext := path.ext(file_path); ext {
        case ".tga":
            image, success, err = read_tga_image(data);
        case:
            success, err = false, "Unsupported file type";
    }
    return image, success , err;
}
