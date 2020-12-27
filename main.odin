package main

import "core:fmt"
import "img_tin"

main :: proc(){

    image_tst := img_tin.create_image(500, 500);
    defer img_tin.free_image(image_tst);

    img_tin.draw_rect(20, 20, 300, 300, image_tst, img_tin.color(0xFF, 0, 0, 0xFF));

    file_path := "D:\\odin_projects\\img_tin\\Release\\test.tga";
    img_tin.write_img_to_file(file_path, image_tst, img_tin.Encoder.TGA);

    /*file_path := "D:\\image_test_files\\tga\\xing_t32.tga";
    out_path := "D:\\image_test_files\\tga\\xing_t32_out.tga";

    image, success, err := img_tin.load_image_from_file(file_path);
    fmt.println(image, success, err);
    img_tin.write_img_to_file(out_path, image, img_tin.Encoder.TGA);
    img_tin.free_image(image);*/
}
