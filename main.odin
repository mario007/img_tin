package main

import "core:fmt"
import "img_tin"

main :: proc(){

    image := img_tin.create_image(500, 500);
    defer img_tin.free_image(image);

    img_tin.draw_rect(20, 20, 300, 300, image, 0xFF0000FF);

    file_path := "D:\\odin_projects\\img_tin\\Release\\test.ppm";
    img_tin.write_img_to_file(file_path, image, img_tin.Encoder.PPM);
}
