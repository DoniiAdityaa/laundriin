import 'package:flutter/material.dart';
import 'package:laundriin/ui/typography.dart';

import '../dimension.dart';

class EmptyView extends StatelessWidget {
  final String? image;
  final String? title;
  final String? description;
  final Widget? action;
  final double? imageSize;
  final double? imageWidth;
  const EmptyView(
      {super.key,
      this.image = "assets/images/asset_riawayat_code_kosong.png",
      this.title = "Data not found",
      this.imageSize = 96,
      this.imageWidth = 96,
      this.description = "We can't find the data your looking for :(",
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: image != null,
              child: Image.asset(
                image ?? "",
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              ),
            ),
            Visibility(
              visible: title != null,
              child: Padding(
                padding: const EdgeInsets.only(top: spacing2),
                child: Text(
                  title ?? "",
                  style: sMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Visibility(
              visible: description != null,
              child: Padding(
                padding: const EdgeInsets.only(top: spacing2),
                child: Text(
                  description ?? "",
                  style: xsRegular,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Visibility(
              visible: action != null,
              child: Padding(
                padding: const EdgeInsets.only(top: spacing2),
                child: action,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
