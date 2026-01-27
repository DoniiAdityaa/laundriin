import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/shared_widget/custom_form_field.dart';
import 'package:laundriin/ui/style.dart';

class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({
    super.key,
    required this.titleSection,
    required this.datePickerController,
    this.helper,
    this.helperText,
    this.onChanged,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.defaultValue,
    this.enabled,
  });

  final DatePickerController datePickerController;
  final String titleSection;
  final Widget? helper;
  final String? helperText;
  final Function(DateTime)? onChanged;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool Function(DateTime)? selectableDayPredicate;
  final DateTime? defaultValue;
  final bool? enabled;

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final _textEditingController = TextEditingController();
  final _dateFormat = "d MMMM y";

  @override
  void initState() {
    DateTime? initialDate = widget.defaultValue;
    widget.datePickerController._controller = _textEditingController;
    try {
      initialDate =
          DateFormat(_dateFormat, 'id_ID').parse(_textEditingController.text);
    } on Exception {
      initialDate =
          initialDate ?? widget.datePickerController.dateTime ?? DateTime.now();
    }
    widget.datePickerController.dateTime = initialDate;
    _textEditingController.text =
        DateFormat(_dateFormat, 'id_ID').format(initialDate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(
      color: textNeutralPrimary,
      fontSize: 14,
      height: 1.6,
    );

    return CustomFormField(
      titleSection: widget.titleSection,
      helper: widget.helper,
      helperText: widget.helperText,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (widget.enabled ?? true)
            ? () {
                debugPrint("Text");
                showDatePicker(
                  context: context,
                  initialDate: widget.datePickerController.dateTime ??
                      widget.defaultValue ??
                      DateTime.now(),
                  firstDate: widget.defaultValue ??
                      widget.firstDate ??
                      DateTime.utc(1900),
                  lastDate: widget.lastDate ?? DateTime.now(),
                  selectableDayPredicate: widget.selectableDayPredicate,
                ).then(
                  (date) {
                    if (date != null) {
                      _textEditingController.text =
                          DateFormat(_dateFormat, 'id_ID').format(date);
                      widget.datePickerController.dateTime = date;
                      if (widget.onChanged != null) {
                        widget.onChanged!(date);
                      }
                    }
                  },
                );
              }
            : null,
        child: IgnorePointer(
          child: TextFormField(
            controller: _textEditingController,
            enabled: widget.enabled,
            decoration: inputDecoration().copyWith(
              hintText: "d MMMM y",
              suffixIcon: SvgPicture.asset('assets/images/ic_calendar.svg'),
              suffixIconConstraints: const BoxConstraints(
                minHeight: 24,
                minWidth: 48,
              ),
            ),
            style: inputStyle,
            validator: (input) {
              if (input == null || input.isEmpty) {
                return "Tolong masukkan tanggal dengan benar.";
              }
              DateTime parsed;

              try {
                parsed = DateFormat(_dateFormat, 'id_ID').parse(input);
                debugPrint(parsed.toString());
              } on Exception catch (e) {
                debugPrint(e.toString());
                return "Format tanggal salah.";
              }

              if (widget.validator != null) {
                return widget.validator!(input);
              }

              return null;
            },
          ),
        ),
      ),
    );
  }
}

class DatePickerController {
  TextEditingController? _controller;
  DateTime? dateTime;

  void clear() {
    if (_controller != null) {
      _controller!.clear();
    }
    dateTime = null;
  }
}
