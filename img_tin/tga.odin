// TGA reader and writer
//
// TGA reader SUPPORT All Image Types!
// 1 - Uncompressed(color-map)
// 2 - Uncompressed(true color)
// 3 - Uncompressed Black and White 
// 9 - RLE color mapped image
// 10 - RLE true color
// 11 - RLE black and white
//
// TGA writer currently only write image type 2(Uncompressed true color)
// TODO - support for image type 9(RLE true color)

package img_tin


read_pixel_color :: inline proc(data: []byte, offset: u32, bytes_per_pixel: u32) -> u32 {
    pix_color : u32 = 0x00000000;
    i := offset;
    switch bytes_per_pixel {
        case 1:
            pix_color = color(data[i], data[i], data[i], 0xFF);
        case 2:
            scale_5_to_8_bits :: inline proc(c: u8) -> u8 { return (c << 3) | (c >> 2);}
            val := u16(data[i+1])<<8 | u16(data[i]);
            r := scale_5_to_8_bits(u8((val >> 10) & 0x1F));
            g := scale_5_to_8_bits(u8((val >> 5) & 0x1F));
            b := scale_5_to_8_bits(u8(val & 0x1F));
            pix_color = color(r, g, b, 0xFF);
        case 3:
            pix_color = color(data[i+2], data[i+1], data[i], 0xFF);
        case 4:
            pix_color = color(data[i+2], data[i+1], data[i], data[i+3]);
    }
    return pix_color;
}


read_tga_image :: proc(data: []byte) -> (Image, bool, string){
   
   // numbers are store in little-endian format
    read_u16 :: proc(d: []byte, i: u32) -> u16 { return u16(d[i+1])<<8 | u16(d[i]);}

    // READING TARGA HEADER
    id_length := u32(data[0]);
    color_map_type := data[1];
    image_type := data[2];

    color_map_first_entry := u32(read_u16(data, 3));
    color_map_length := u32(read_u16(data, 5));
    color_map_entry_size := u32(data[7]);

    x_origin := read_u16(data, 8);
    y_origin := read_u16(data, 10);
    width := u32(read_u16(data, 12));
    height := u32(read_u16(data, 14));
    pixel_depth := u32(data[16]);
    image_descriptor := data[17];

    if (pixel_depth !=8 && pixel_depth !=15 && pixel_depth != 16 && pixel_depth != 24 && pixel_depth != 32) {
         err := "unsupported pixel depth in TARGA file";
        return create_image(0, 0), false, err;
    }

    bytes_per_pixel_map : u32 = 0;
    if image_type == 1 || image_type == 9 {
        bytes_per_pixel_map = (color_map_entry_size + 7) / 8; // color_map_entry_size can be 15-bits(we round on 2 byte)
    }

    flipped_x := bool(image_descriptor & 0x10);
    flipped_y := !bool(image_descriptor & 0x20);

    bytes_per_pixel := (pixel_depth + 7) / 8;
    header_size : u32 = 18;
    offset := header_size + id_length + color_map_length * bytes_per_pixel_map;
    image := create_image(width, height);

    start_map_offset := header_size + id_length + color_map_first_entry * bytes_per_pixel_map;
    color : u32 = 0x00000000;

    rle_processing, rle_packet, rle_counter := false, false, 0;

    for y in 0..<height {
        for x in 0..<width{
            switch image_type {
                case 1:
                    map_offset := start_map_offset + u32(data[offset]) * bytes_per_pixel_map;
                    color = read_pixel_color(data, map_offset, bytes_per_pixel_map);
                case 2:
                    fallthrough;
                case 3:
                    color = read_pixel_color(data, offset, bytes_per_pixel);
                case 9:
                    fallthrough;
                case 10:
                    fallthrough;
                case 11:
                    if rle_processing {
                        if rle_packet {
                            offset -= bytes_per_pixel;
                            rle_counter -= 1;
                            if rle_counter == 0 { rle_processing=false; }
                        } else {
                            if image_type == 9 {
                                map_offset := start_map_offset + u32(data[offset]) * bytes_per_pixel_map;
                                color = read_pixel_color(data, map_offset, bytes_per_pixel_map);
                            } else {
                                color = read_pixel_color(data, offset, bytes_per_pixel);
                            }
                            rle_counter -= 1;
                            if rle_counter == 0 { rle_processing=false; }
                        }

                    } else {
                        rle_packet = bool(data[offset] & 0x80);
                        rle_counter = int(data[offset] & 0x7F);
                        offset += 1;
                        if image_type == 9 {
                            map_offset := start_map_offset + u32(data[offset]) * bytes_per_pixel_map;
                            color = read_pixel_color(data, map_offset, bytes_per_pixel_map);
                        } else {
                            color = read_pixel_color(data, offset, bytes_per_pixel);
                        }
                        if rle_counter > 0 { rle_processing = true; }
                    }
            }
            cur_x, cur_y := x, y;
            if flipped_x { cur_x = width - 1 - x;} 
            if flipped_y { cur_y = height - 1 - y;} 
            set_pixel(cur_x, cur_y, image, color);
            offset += bytes_per_pixel;
        }
    }

    return image, true, "";
}


generate_tga_data :: proc(image: Image, data: ^Data){

    append(&data.buf, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    width: [4]u8 = transmute([4]u8)image.width;
    height: [4]u8 = transmute([4]u8)image.height;
    append(&data.buf, width[0], width[1], height[0], height[1], 32, 0x20);

    // write image data
    for y in 0..<image.height {
        for x in 0..<image.width{
            color := get_pixel(x, y, image);
            rgba: [4]u8 = transmute([4]u8)color;
            append(&data.buf, rgba[1], rgba[2], rgba[3], rgba[0]);
        }
    }
}
