import 'package:flutter/material.dart';

class autoFill extends StatefulWidget {
  bool needBorder = true;
  TextEditingController controller = TextEditingController();
  List<String> optionsList = [];
  String labelText = "";
  FocusNode? focusNode;
  FocusNode? nextFocusNode;
  Function? onSubmitCallback;
  autoFill(
      {super.key,
      required this.controller,
      required this.optionsList,
      required this.labelText,
      this.focusNode,
      this.nextFocusNode,
      this.onSubmitCallback,
      this.needBorder = true});

  @override
  State<autoFill> createState() => _autoFillState();
}

class _autoFillState extends State<autoFill> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        List<String> options = widget.optionsList;

        // Return suggestions that contain the input text
        return options.where((String option) {
          return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        }).toList();
      },
      optionsMaxHeight: 200,
      displayStringForOption: (String option) => option,
      fieldViewBuilder:
          (context, subjectNameController, focusNode, onEditingComplete) {
        return TextField(
          controller: subjectNameController,
          focusNode: focusNode,
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.arrow_drop_down),
            labelText: widget.labelText,
            border: widget.needBorder
                ? OutlineInputBorder()
                : OutlineInputBorder(borderSide: BorderSide.none),
          ),
          onEditingComplete: () {
            onEditingComplete();
            widget.nextFocusNode?.requestFocus();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: 200,
              height: options.length * 50.0,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      widget.controller.text = option;
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (String selection) {
        print('You selected: $selection');

        if (widget.onSubmitCallback != null) {
          widget.onSubmitCallback!(selection);
        }
      },
    );
  }
}
