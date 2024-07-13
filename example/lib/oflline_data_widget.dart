//create an offline data widget

import 'package:flutter/material.dart';

import 'package:polar/polar.dart';

class OfflineDataWidget extends StatelessWidget {
  final PolarOfflineRecordingData data;
  const OfflineDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Offline data'),
      ),
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Type: ${data.type}'),
                Text('Start time: ${data.startTime}'),
                if (data.settings != null) Text('Settings: ${data.settings}'),
                if (data.accData != null)
                  for (var acc in data.accData!.samples)
                    Text('Acc data: ${acc.x} ${acc.y} ${acc.z}'),
                if (data.gyroData != null)
                  for (var gyro in data.gyroData!.samples)
                    Text('Gyro data: ${gyro.x} ${gyro.y} ${gyro.z}'),
                if (data.magData != null)
                  for (var mag in data.magData!.samples)
                    Text('Mag data: ${mag.x} ${mag.y} ${mag.z}'),
                if (data.hrData != null)
                  for (var hr in data.hrData!.samples)
                    Text('Hr data: ${hr.hr}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
