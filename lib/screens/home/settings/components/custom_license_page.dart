import 'dart:async';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomLicensePage extends StatelessWidget {
  final String applicationName;
  final String applicationVersion;
  const CustomLicensePage({Key? key, required this.applicationName, required this.applicationVersion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _CustomLicensePageBuilder(
        (context, licenseDataFuture){
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Get.theme.appBarTheme.foregroundColor,
                title: const Text("Licenses"),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 25,),
                    Text(applicationName, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25, color: Get.theme.colorScheme.primary),),
                    Text(applicationVersion, style: const TextStyle(color: Colors.grey, fontSize: 12),),
                    const SizedBox(height: 25,),
                  ],
                )
              ),
              Builder(
                builder: (context){
                  switch (licenseDataFuture.connectionState) {
                    case ConnectionState.done:
                      LicenseData? licenseData = licenseDataFuture.data;
                      return SliverGrid.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                        children: [
                          ...licenseDataFuture.data!.packages.map(
                            (currentPackage) => TextButton(
                              child: Column(
                                children: [
                                  Text(currentPackage, style: const TextStyle(fontSize: 17,),),
                                  Text("${licenseData!.packageLicenseBindings[currentPackage]!.length} Licenses", style: TextStyle(color: Theme.of(context).textTheme.titleSmall!.color,),),
                                ],
                              ),
                              onPressed: () {
                                List<LicenseEntry> packageLicenses = licenseData
                                  .packageLicenseBindings[currentPackage]!
                                  .map((binding) => licenseData.licenses[binding])
                                  .toList();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return Scaffold(
                                        appBar: AppBar(
                                          title: Text(currentPackage),
                                        ),
                                        body: SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(25),
                                                child: Text(
                                                  packageLicenses
                                                      .map(
                                                        (e) => e.paragraphs
                                                        .map((e) => e.text)
                                                        .toList()
                                                        .reduce((value, element) => "$value\n$element",),
                                                  ).reduce((value, element) => "$value\n\n$element",),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                            ),
                          ),
                        ],
                      );

                    default: return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomLicensePageBuilder extends StatefulWidget {
  const _CustomLicensePageBuilder(
      this.builder, {
        Key? key,
      }) : super(key: key);

  final Widget Function(BuildContext, AsyncSnapshot<LicenseData>) builder;

  @override
  _CustomLicensePageBuilderState createState() => _CustomLicensePageBuilderState();
}

class _CustomLicensePageBuilderState extends State<_CustomLicensePageBuilder> {
  final ValueNotifier<int?> selectedId = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseData>(
      future: licenses,
      builder: widget.builder,
    );
  }

  final Future<LicenseData> licenses = LicenseRegistry.licenses
      .fold<LicenseData>(
    LicenseData(),
        (LicenseData prev, LicenseEntry license) => prev..addLicense(license),
  )
      .then((LicenseData licenseData) => licenseData..sortPackages());
}

class LicenseData {
  final List<LicenseEntry> licenses = <LicenseEntry>[];
  final Map<String, List<int>> packageLicenseBindings = <String, List<int>>{};
  final List<String> packages = <String>[];

  String? firstPackage;

  void addLicense(LicenseEntry entry) {
    for (final String package in entry.packages) {
      _addPackage(package);
      packageLicenseBindings[package]!.add(licenses.length);
    }
    licenses.add(entry);
  }

  void _addPackage(String package) {
    if (!packageLicenseBindings.containsKey(package)) {
      packageLicenseBindings[package] = <int>[];
      firstPackage ??= package;
      packages.add(package);
    }
  }

  void sortPackages([int Function(String a, String b)? compare]) {
    packages.sort(
      compare ?? (String a, String b) {
        if (a == firstPackage) {
          return -1;
        }
        if (b == firstPackage) {
          return 1;
        }
        return a.toLowerCase().compareTo(b.toLowerCase());
      }
    );
  }
}