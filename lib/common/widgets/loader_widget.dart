import 'package:flutter/material.dart';

import '../../utilities/const.dart';

class LoaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: cPrimary,
      ),
    );
  }
}
