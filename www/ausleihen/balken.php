<?php

#
# Copyright (C) 2008 Gernot Deinzer
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#


        $value = $_REQUEST['proz'];


        $val = round($value *4);

        $img_w = 400; 
        $img_h = 10; 



        $red =  128;
        $green = 0;
        $blue = 64;




        $ih = imagecreate($img_w, $img_h);



        $hist_color = imagecolorallocate($ih, $red, $green, $blue);

$black = imagecolorallocate($ih, 0, 0, 0);

        $white = imagecolorallocate($ih, 255, 255, 255);
        imagefill($ih, 0, 0, $white); 

        imagefilledrectangle($ih, 0, 0, $val, 10, $hist_color);

       imageline($ih, 100, 0, 100, 10, $black);
       imageline($ih, 200, 0, 200, 10, $black);
       imageline($ih, 300, 0, 300, 10, $black);


         header('Content-Type: image/png');
         ImagePNG($ih);


?>
