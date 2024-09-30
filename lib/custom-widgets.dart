import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomDrawerItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int page;
  final int selectedPage;
  final Function onTap;
  bool isMenuExpanded;

  CustomDrawerItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
    required this.selectedPage,
    required this.onTap,
    required this.isMenuExpanded,
  }) : super(key: key);

  @override
  _CustomDrawerItemState createState() => _CustomDrawerItemState();
}

class _CustomDrawerItemState extends State<CustomDrawerItem> {
  bool isHovered = false;
  final GlobalKey<TooltipState> tooltipkey = GlobalKey<TooltipState>();
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => setState(() {
        isHovered = true;
      }),
      onExit: (event) => setState(() {
        isHovered = false;
      }),
      child: Tooltip(
        key: tooltipkey,
        showDuration: const Duration(seconds: 1),
        message: widget.isMenuExpanded ? "" : widget.label,
        height: 20.0,
        padding: EdgeInsets.all(5.0),
        margin: EdgeInsets.only(left: 60.0),
        verticalOffset: 10,
        preferBelow: false,
        enableFeedback: true,
        child: GestureDetector(
          onTap: () => widget.onTap(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            width: widget.isMenuExpanded ? 200.0 : 50.0,
            height: 50.0,
            margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.selectedPage == widget.page
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
              ),
              color: widget.selectedPage == widget.page
                  ? Colors.white
                      .withOpacity(0.2) // Highlight background if selected
                  : isHovered
                      ? Colors.white
                          .withOpacity(0.1) // Background color on hover
                      : Colors.transparent, // Default background
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  widget.selectedPage == widget.page
                      ? widget.selectedIcon
                      : widget.icon,
                  color: widget.selectedPage == widget.page
                      ? Colors.white // Change to highlight color if selected
                      : isHovered
                          ? Colors.white // Change icon color on hover
                          : Color.fromRGBO(
                              255, 255, 255, .7), // Default icon color
                ),
                widget.isMenuExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: widget.selectedPage == widget.page
                                ? Colors
                                    .white // Change to highlight color if selected
                                : isHovered
                                    ? Colors.white // Change text color on hover
                                    : Color.fromRGBO(255, 255, 255,
                                        .7), // Default text color
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AutoFill extends StatefulWidget {
  bool needBorder;
  TextEditingController controller;
  List<String> optionsList;
  String labelText;
  FocusNode? focusNode;
  FocusNode? nextFocusNode;
  Function? onSubmitCallback;

  AutoFill({
    super.key,
    required this.controller,
    required this.optionsList,
    required this.labelText,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitCallback,
    this.needBorder = true,
  });

  @override
  State<AutoFill> createState() => _AutoFillState();
}

class _AutoFillState extends State<AutoFill> {
  String? selectedValue; // Track the selected value

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        filled: widget.needBorder ? true : false,
        fillColor: Theme.of(context).canvasColor,
        focusedBorder: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(15.0),
        border: widget.needBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.2),
                  width: 0.4,
                ),
              )
            : const OutlineInputBorder(borderSide: BorderSide.none),
      ),
      value: selectedValue ??
          (widget.controller.text.isNotEmpty
              ? widget.controller.text
              : null), // Initialize with the controller value if available
      items: widget.optionsList.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            // Update controller with the selected value
            selectedValue = newValue;
            widget.controller.text = newValue;

            // Move focus to next field, if provided
            widget.nextFocusNode?.requestFocus();

            // Call the submit callback, if available
            if (widget.onSubmitCallback != null) {
              widget.onSubmitCallback!(newValue);
            }
          }
        });
      },
    );
  }
}

class autoFill2 extends StatefulWidget {
  bool needBorder = true;
  TextEditingController controller = TextEditingController();
  List<String> optionsList = [];
  String labelText = "";
  FocusNode? focusNode;
  FocusNode? nextFocusNode;
  Function? onSubmitCallback;
  autoFill2(
      {super.key,
      required this.controller,
      required this.optionsList,
      required this.labelText,
      this.focusNode,
      this.nextFocusNode,
      this.onSubmitCallback,
      this.needBorder = true});

  @override
  State<autoFill2> createState() => _autoFillState();
}

class _autoFillState extends State<autoFill2> {
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
          enabled: widget.labelText == 'Subject' && widget.optionsList.isEmpty
              ? false
              : true,
          controller: subjectNameController,
          focusNode: focusNode,
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.arrow_drop_down),
            label: Text(
              widget.labelText,
            ),
            filled: widget.needBorder ? true : false,
            fillColor: Theme.of(context).canvasColor,
            focusColor: Colors.grey,
            contentPadding: const EdgeInsets.all(15.0),
            border: widget.needBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(
                        color: Colors.grey.withOpacity(.2), width: 0.4),
                  )
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
