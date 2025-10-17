import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectionWidget extends StatefulWidget {
  final String plan;
  final DateTime startDate;
  final List<DateTime> selectedDates;
  final Function(DateTime) onDateSelected;
  final Function(List<DateTime>) onWeeklyDatesSelected;
  final Function(List<DateTime>) onMonthlyDatesSelected;

  const DateSelectionWidget({
    super.key,
    required this.plan,
    required this.startDate,
    required this.selectedDates,
    required this.onDateSelected,
    required this.onWeeklyDatesSelected,
    required this.onMonthlyDatesSelected,
  });

  @override
  State<DateSelectionWidget> createState() => _DateSelectionWidgetState();
}

class _DateSelectionWidgetState extends State<DateSelectionWidget> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
    );

    if (picked != null && picked != widget.startDate && mounted) {
      widget.onDateSelected(picked);
    }
  }

  Future<void> _selectWeeklyDates(BuildContext context) async {
    final DateTime? firstDate = await showDatePicker(
      context: context,
      initialDate: widget.startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start of week',
    );

    if (firstDate == null || !mounted) return;

    final List<DateTime> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(firstDate.add(Duration(days: i)));
    }

    final List<DateTime>? selected = await showDialog(
      context: context,
      builder: (context) => WeeklyDatesDialog(
        weekDates: weekDates,
        selectedDates: widget.selectedDates,
      ),
    );

    if (selected != null && mounted) {
      widget.onWeeklyDatesSelected(selected);
    }
  }

  Future<void> _selectMonthlyDates(BuildContext context) async {
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: widget.startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start of month',
    );

    if (startDate == null || !mounted) return;

    final DateTime endDate = startDate.add(const Duration(days: 30));

    final List<DateTime>? selected = await showDialog(
      context: context,
      builder: (context) => MonthlyDatesDialog(
        startDate: startDate,
        endDate: endDate,
        selectedDates: widget.selectedDates,
      ),
    );

    if (selected != null && mounted) {
      widget.onMonthlyDatesSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select ${widget.plan} Dates',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        if (widget.plan == 'Weekly') ...[
          _buildDateRangeButtons(context),
          const SizedBox(height: 8),
          WeeklyDateSelection(
            selectedDates: widget.selectedDates,
            onSelectDates: () => _selectWeeklyDates(context),
            onRemoveDate: (date) {
              final newDates = List<DateTime>.from(widget.selectedDates)
                ..remove(date);
              widget.onWeeklyDatesSelected(newDates);
            },
          ),
        ] else if (widget.plan == 'Monthly') ...[
          _buildDateRangeButtons(context),
          const SizedBox(height: 8),
          MonthlyDateSelection(
            startDate: widget.startDate,
            endDate: widget.startDate.add(const Duration(days: 30)),
            selectedDates: widget.selectedDates,
            onSelectDates: () => _selectMonthlyDates(context),
            onRemoveDate: (date) {
              final newDates = List<DateTime>.from(widget.selectedDates)
                ..remove(date);
              widget.onMonthlyDatesSelected(newDates);
            },
          ),
        ] else ...[
          _buildSingleDateButton(context),
        ],
      ],
    );
  }

  Widget _buildSingleDateButton(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Date',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(widget.startDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              if (widget.plan == 'Weekly') {
                _selectWeeklyDates(context);
              } else {
                _selectMonthlyDates(context);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Select Dates',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              if (widget.plan == 'Weekly') {
                final List<DateTime> allWeekDates = [];
                for (int i = 0; i < 7; i++) {
                  allWeekDates.add(widget.startDate.add(Duration(days: i)));
                }
                widget.onWeeklyDatesSelected(allWeekDates);
              } else {
                final List<DateTime> allMonthDates = [];
                for (int i = 0; i < 30; i++) {
                  allMonthDates.add(widget.startDate.add(Duration(days: i)));
                }
                widget.onMonthlyDatesSelected(allMonthDates);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.select_all, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Select All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MonthlyDatesDialog extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> selectedDates;

  const MonthlyDatesDialog({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedDates,
  });

  @override
  State<MonthlyDatesDialog> createState() => _MonthlyDatesDialogState();
}

class _MonthlyDatesDialogState extends State<MonthlyDatesDialog> {
  late List<DateTime> _tempSelectedDates;

  @override
  void initState() {
    super.initState();
    _tempSelectedDates = List.from(widget.selectedDates);
  }

  @override
  Widget build(BuildContext context) {
    final monthDates = _generateMonthDates();
    final allSelected = _tempSelectedDates.length == monthDates.length;

    return AlertDialog(
      title: const Text('Select Delivery Days'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${DateFormat('MMM yyyy').format(widget.startDate)} - ${DateFormat('MMM yyyy').format(widget.endDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Select specific days or choose all days'),
            const SizedBox(height: 16),

            // Quick selection buttons
            Row(
              children: [
                _buildQuickSelectButton('Weekdays', () {
                  setState(() {
                    _tempSelectedDates = monthDates.where((date) {
                      return date.weekday != DateTime.saturday &&
                          date.weekday != DateTime.sunday;
                    }).toList();
                  });
                }, icon: Icons.work),
                const SizedBox(width: 8),
                _buildQuickSelectButton('Weekends', () {
                  setState(() {
                    _tempSelectedDates = monthDates.where((date) {
                      return date.weekday == DateTime.saturday ||
                          date.weekday == DateTime.sunday;
                    }).toList();
                  });
                }, icon: Icons.weekend),
              ],
            ),
            const SizedBox(height: 16),

            // Date selection list
            SizedBox(
              height: 300,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('All Days'),
                    value: allSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        _tempSelectedDates = value == true ? monthDates : [];
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: monthDates.length,
                      itemBuilder: (context, index) {
                        final date = monthDates[index];
                        return CheckboxListTile(
                          title: Text(
                            DateFormat('EEEE, MMM d').format(date),
                            style: TextStyle(
                              color:
                                  date.weekday == DateTime.saturday ||
                                      date.weekday == DateTime.sunday
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                          value: _tempSelectedDates.contains(date),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedDates.add(date);
                              } else {
                                _tempSelectedDates.remove(date);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _tempSelectedDates),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildQuickSelectButton(
    String label,
    VoidCallback onPressed, {
    IconData? icon,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  List<DateTime> _generateMonthDates() {
    final List<DateTime> dates = [];
    for (
      int i = 0;
      i <= widget.endDate.difference(widget.startDate).inDays;
      i++
    ) {
      dates.add(widget.startDate.add(Duration(days: i)));
    }
    return dates;
  }
}

class WeeklyDatesDialog extends StatefulWidget {
  final List<DateTime> weekDates;
  final List<DateTime> selectedDates;

  const WeeklyDatesDialog({
    super.key,
    required this.weekDates,
    required this.selectedDates,
  });

  @override
  State<WeeklyDatesDialog> createState() => _WeeklyDatesDialogState();
}

class _WeeklyDatesDialogState extends State<WeeklyDatesDialog> {
  late List<DateTime> _tempSelectedDates;

  @override
  void initState() {
    super.initState();
    _tempSelectedDates = List.from(widget.selectedDates);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _tempSelectedDates.length == widget.weekDates.length;

    return AlertDialog(
      title: const Text('Select Delivery Days'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Week of ${DateFormat('MMM d, yyyy').format(widget.weekDates.first)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Quick selection buttons
            Row(
              children: [
                _buildQuickSelectButton('Weekdays', () {
                  setState(() {
                    _tempSelectedDates = widget.weekDates.where((date) {
                      return date.weekday != DateTime.saturday &&
                          date.weekday != DateTime.sunday;
                    }).toList();
                  });
                }, icon: Icons.work),
                const SizedBox(width: 8),
                _buildQuickSelectButton('Weekends', () {
                  setState(() {
                    _tempSelectedDates = widget.weekDates.where((date) {
                      return date.weekday == DateTime.saturday ||
                          date.weekday == DateTime.sunday;
                    }).toList();
                  });
                }, icon: Icons.weekend),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 300,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('All Days'),
                    value: allSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        _tempSelectedDates = value == true
                            ? List.from(widget.weekDates)
                            : [];
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.weekDates.length,
                      itemBuilder: (context, index) {
                        final date = widget.weekDates[index];
                        return CheckboxListTile(
                          title: Text(
                            DateFormat('EEEE, MMM d').format(date),
                            style: TextStyle(
                              color:
                                  date.weekday == DateTime.saturday ||
                                      date.weekday == DateTime.sunday
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                          value: _tempSelectedDates.contains(date),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedDates.add(date);
                              } else {
                                _tempSelectedDates.remove(date);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _tempSelectedDates),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildQuickSelectButton(
    String label,
    VoidCallback onPressed, {
    IconData? icon,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class WeeklyDateSelection extends StatefulWidget {
  final List<DateTime> selectedDates;
  final VoidCallback onSelectDates;
  final Function(DateTime) onRemoveDate;

  const WeeklyDateSelection({
    super.key,
    required this.selectedDates,
    required this.onSelectDates,
    required this.onRemoveDate,
  });

  @override
  State<WeeklyDateSelection> createState() => _WeeklyDateSelectionState();
}

class _WeeklyDateSelectionState extends State<WeeklyDateSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Delivery Days:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (widget.selectedDates.isEmpty)
          const Text('No days selected', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedDates.map((date) {
              final isWeekend =
                  date.weekday == DateTime.saturday ||
                  date.weekday == DateTime.sunday;
              return Chip(
                label: Text(
                  DateFormat('EEE, MMM d').format(date),
                  style: TextStyle(color: isWeekend ? Colors.red : null),
                ),
                backgroundColor: isWeekend ? Colors.red.withOpacity(0.1) : null,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => widget.onRemoveDate(date),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class SingleDateSelection extends StatefulWidget {
  final DateTime date;
  final VoidCallback onSelectDate;

  const SingleDateSelection({
    super.key,
    required this.date,
    required this.onSelectDate,
  });

  @override
  State<SingleDateSelection> createState() => _SingleDateSelectionState();
}

class _SingleDateSelectionState extends State<SingleDateSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onSelectDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Date',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MonthlyDateSelection extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> selectedDates;
  final VoidCallback onSelectDates;
  final Function(DateTime) onRemoveDate;

  const MonthlyDateSelection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedDates,
    required this.onSelectDates,
    required this.onRemoveDate,
  });

  @override
  State<MonthlyDateSelection> createState() => _MonthlyDateSelectionState();
}

class _MonthlyDateSelectionState extends State<MonthlyDateSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateFormat('MMM d, yyyy').format(widget.startDate)} - ${DateFormat('MMM d, yyyy').format(widget.endDate)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selected Delivery Days:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (widget.selectedDates.isEmpty)
          const Text('No days selected', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedDates.map((date) {
              final isWeekend =
                  date.weekday == DateTime.saturday ||
                  date.weekday == DateTime.sunday;
              return Chip(
                label: Text(
                  DateFormat('EEE, MMM d').format(date),
                  style: TextStyle(color: isWeekend ? Colors.red : null),
                ),
                backgroundColor: isWeekend ? Colors.red.withOpacity(0.1) : null,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => widget.onRemoveDate(date),
              );
            }).toList(),
          ),
      ],
    );
  }
}
