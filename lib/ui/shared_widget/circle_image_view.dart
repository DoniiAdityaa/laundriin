
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


enum ImageType{
  network,
  asset,
  file
}

class CircleImageView extends StatelessWidget {
  final String? url;
  final String? imageAsset;
  final File? imageFile;
  final double radius;
  final ImageType imageType;
  final BoxFit fit;
  const CircleImageView({super.key, this.url, this.imageAsset, this.imageFile, this.radius = 50, this.imageType = ImageType.network,  this.fit = BoxFit.cover });

  @override
  Widget build(BuildContext context) {
    switch(imageType){
      case ImageType.network : return ClipOval(
        child: SizedBox.fromSize(size: Size.fromRadius(radius),
        child: CachedNetworkImage(imageUrl: url ?? "", memCacheHeight: 400,placeholder: (context,url)=> const Center(child: CircularProgressIndicator()), errorWidget: (context,url,error)=> Image.asset(imageAsset ?? "assets/images/img_profil_default.jpg",fit: fit,),fit: fit,),
        ));
      case ImageType.asset : return  ClipOval(
        child: SizedBox.fromSize(size: Size.fromRadius(radius),
        child: Image.asset(imageAsset ?? "assets/images/img_null.png",fit: fit,),
      ));
      case ImageType.file : return ClipOval(
    child: SizedBox.fromSize(size: Size.fromRadius(radius),
        child: Image.file(imageFile ?? File(""),fit: fit,),
      ));
    }
  }
}
