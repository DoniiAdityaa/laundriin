import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ui/color.dart';
import '../../../ui/dimension.dart';

import '../../../ui/style.dart';
import '../../../ui/typography.dart';

class ConfirmImageScreen extends StatefulWidget {
  final File initialFile;
  final ImageSource imageSource;

  const ConfirmImageScreen(
      {super.key, required this.initialFile, required this.imageSource});

  @override
  State<ConfirmImageScreen> createState() => _ConfirmImageScreenState();
}

class _ConfirmImageScreenState extends State<ConfirmImageScreen> {
  late File _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainView(context);
  }

  Widget _buildMainView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: transparentColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildImageResultView()),
            _buildFooterView(context: context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageResultView() {
    return Container(
      padding: const EdgeInsets.all(screenPadding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 600,
              child: Image.file(
                _selectedFile,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: space300),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: space300, vertical: space300),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: bgSurfaceInfo,
                  borderRadius: BorderRadius.circular(borderRadius200)),
              child: RichText(
                text: TextSpan(
                  text: "Pastikan tanda tangan ",
                  style: sRegular.copyWith(color: textInfo),
                  children: [
                    TextSpan(
                        text: "jelas, tidak terpotong, ",
                        style: sMedium.copyWith(color: blue700)),
                    TextSpan(
                        text: "dan mendapat ",
                        style: sRegular.copyWith(color: textInfo)),
                    TextSpan(
                        text: "cahaya yang terang",
                        style: sMedium.copyWith(color: blue700)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFooterView({required BuildContext context}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: borderNeutral,
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: screenPadding, vertical: screenPadding),
          child: Column(
            children: [
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedFile);
                    },
                    style: elevatedButtonLargeStyle,
                    child: Text("Gunakan"),
                  )),
              SizedBox(
                height: space300,
              ),
            ],
          ),
        )
      ],
    );
  }
}
