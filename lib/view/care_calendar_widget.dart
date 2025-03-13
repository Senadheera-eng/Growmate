// care_calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../model/tree_stats_model.dart';
import '../model/tree_model.dart';

class CareCalendarWidget extends StatefulWidget {
  final Map<DateTime, List<TreeActivity>> events;
  final Function(TreeActivity) onEventTap;
  
  const CareCalendarWidget({
    Key? key,
    required this.events,
    required this.onEventTap,
  }) : super(key: key);

  @override
  _CareCalendarWidgetState createState() => _CareCalendarWidgetState();
}

class _CareCalendarWidgetState extends State<CareCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }
  
  List<TreeActivity> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return widget.events[normalizedDay] ?? [];
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.teal.shade200,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        _selectedDay == null
            ? const Expanded(
                child: Center(child: Text('Select a day to see activities')),
              )
            : Expanded(
                child: _buildEventsList(_getEventsForDay(_selectedDay!)),
              ),
      ],
    );
  }
  
  Widget _buildEventsList(List<TreeActivity> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No activities for this day'),
      );
    }
    
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getEventColor(event.type, event.successful),
              child: Icon(
                _getEventIcon(event.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description.length > 50
                      ? '${event.description.substring(0, 50)}...'
                      : event.description,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(event.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => widget.onEventTap(event),
          ),
        );
      },
    );
  }
  
  Color _getEventColor(String type, bool? successful) {
    if (type == 'care_tip') {
      return Colors.green;
    } else if (type == 'treatment_start') {
      return Colors.blue;
    } else if (type == 'treatment_complete') {
      if (successful == true) {
        return Colors.teal;
      } else if (successful == false) {
        return Colors.orange;
      }
      return Colors.grey;
    }
    return Colors.grey;
  }
  
  IconData _getEventIcon(String type) {
    switch (type) {
      case 'care_tip':
        return Icons.eco;
      case 'treatment_start':
        return Icons.medical_services;
      case 'treatment_complete':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }
}