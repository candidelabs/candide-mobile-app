import 'package:flutter/material.dart';

class OnboardingFeatureCard extends StatelessWidget {
  final String title;
  final Icon icon;
  const OnboardingFeatureCard({Key? key, required this.title, required this.icon}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        shape: const BeveledRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10))),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 5,),
              icon,
              const SizedBox(width: 7,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(title, style: const TextStyle(fontSize: 18))]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
