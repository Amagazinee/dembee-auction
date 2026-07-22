import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../services/qpay_service.dart';

enum QPayBankLaunchResult {
  openedApp,
  openedStore,
  failed,
}

class _BankStoreTarget {
  const _BankStoreTarget({
    required this.schemes,
    required this.keywords,
    required this.androidPackage,
    this.iosAppId,
    required this.storeSearchName,
  });

  final List<String> schemes;
  final List<String> keywords;
  final String androidPackage;
  final String? iosAppId;
  final String storeSearchName;
}

/// QPay банкны deep link нээх — апп байвал шууд, байхгүй бол Store руу.
class QPayBankLauncher {
  static const _targets = <_BankStoreTarget>[
    _BankStoreTarget(
      schemes: ['qpaywallet', 'qpay'],
      keywords: ['qpay wallet', 'qpay'],
      androidPackage: 'com.qpay.wallet',
      iosAppId: '1501873159',
      storeSearchName: 'QPAY wallet',
    ),
    _BankStoreTarget(
      schemes: ['khanbank'],
      keywords: ['khan bank', 'khanbank', 'хаан'],
      androidPackage: 'com.khanbank.retail',
      storeSearchName: 'Khan Bank',
    ),
    _BankStoreTarget(
      schemes: ['tdbbank', 'tdb'],
      keywords: ['tdb online', 'tdb', 'худалдаа хөгжлийн'],
      androidPackage: 'mn.tdb.pay',
      storeSearchName: 'TDB Online Banking',
    ),
    _BankStoreTarget(
      schemes: ['socialpay-payment', 'socialpay'],
      keywords: ['socialpay', 'social pay'],
      androidPackage: 'mn.egolomt.socialpay',
      storeSearchName: 'SocialPay',
    ),
    _BankStoreTarget(
      schemes: ['statebankmongolia', 'gyalsbank'],
      keywords: ['state bank', 'statebank', 'гялс', 'төрийн'],
      androidPackage: 'com.statebank.gyalsbank',
      storeSearchName: 'State Bank',
    ),
    _BankStoreTarget(
      schemes: ['xacbank', 'xac'],
      keywords: ['xacbank', 'xac bank', 'хас'],
      androidPackage: 'com.xacbank.mobile',
      storeSearchName: 'XacBank',
    ),
    _BankStoreTarget(
      schemes: ['capitronbank', 'capitron'],
      keywords: ['capitron'],
      androidPackage: 'com.capitron',
      storeSearchName: 'Capitron Digital Bank',
    ),
    _BankStoreTarget(
      schemes: ['bogdbank', 'bogd'],
      keywords: ['bogd bank', 'bogd'],
      androidPackage: 'com.bogdbank.ebank.v2',
      storeSearchName: 'Bogd Mobile',
    ),
    _BankStoreTarget(
      schemes: ['nibank'],
      keywords: ['nibank', 'ni bank', 'national investment'],
      androidPackage: 'mn.nib.nibank',
      iosAppId: '6480429353',
      storeSearchName: 'Digital Nibank',
    ),
    _BankStoreTarget(
      schemes: ['most', 'mostmoney'],
      keywords: ['mostmoney', 'most money'],
      androidPackage: 'mn.grapecity.mostmoney',
      storeSearchName: 'Most Money',
    ),
    _BankStoreTarget(
      schemes: ['transbank'],
      keywords: ['transbank', 'trans bank'],
      androidPackage: 'com.transbank.transbankmobile',
      storeSearchName: 'TransBank',
    ),
    _BankStoreTarget(
      schemes: ['mbank'],
      keywords: ['m bank', 'mbank'],
      androidPackage: 'mn.mllc.mbank',
      storeSearchName: 'M bank',
    ),
    _BankStoreTarget(
      schemes: ['arig'],
      keywords: ['arig bank', 'arig', 'ариг'],
      androidPackage: 'mn.arig.online',
      storeSearchName: 'Arig Online',
    ),
    _BankStoreTarget(
      schemes: ['ckbank', 'chinggis'],
      keywords: ['chinggis', 'ck bank', 'чингис'],
      androidPackage: 'mn.ckbank.smartbank',
      iosAppId: '1180620714',
      storeSearchName: 'Smartbank CKBANK',
    ),
    _BankStoreTarget(
      schemes: ['golomtbank', 'golomt'],
      keywords: ['golomt bank', 'golomt', 'голомт'],
      androidPackage: 'mn.egolomt.new.bank',
      storeSearchName: 'Golomt Bank',
    ),
    _BankStoreTarget(
      schemes: ['monpay'],
      keywords: ['monpay'],
      androidPackage: 'mn.monpay.wallet',
      storeSearchName: 'Monpay',
    ),
    _BankStoreTarget(
      schemes: ['toki'],
      keywords: ['toki'],
      androidPackage: 'com.toki.mn',
      storeSearchName: 'Toki',
    ),
    _BankStoreTarget(
      schemes: ['ard'],
      keywords: ['ard app', 'ard'],
      androidPackage: 'mn.ard.android',
      storeSearchName: 'ARD App',
    ),
    _BankStoreTarget(
      schemes: ['hipay'],
      keywords: ['hipay'],
      androidPackage: 'mn.hipay.wallet',
      storeSearchName: 'Hipay',
    ),
    _BankStoreTarget(
      schemes: ['tdbwallet'],
      keywords: ['happy pay', 'tdb wallet'],
      androidPackage: 'mn.tdb.wallet',
      storeSearchName: 'Happy Pay',
    ),
    _BankStoreTarget(
      schemes: ['sono'],
      keywords: ['sono'],
      androidPackage: 'mn.sono.pay',
      storeSearchName: 'Sono',
    ),
    _BankStoreTarget(
      schemes: ['payon'],
      keywords: ['payon'],
      androidPackage: 'com.payon.mn',
      storeSearchName: 'PayOn',
    ),
    _BankStoreTarget(
      schemes: ['tino'],
      keywords: ['tino'],
      androidPackage: 'com.tino.mn',
      storeSearchName: 'Tino',
    ),
  ];

  static Future<QPayBankLaunchResult> launchBankLink(
    QPayBankLink bank,
  ) async {
    if (bank.link.isEmpty) return QPayBankLaunchResult.failed;

    final deepLink = Uri.tryParse(bank.link);
    if (deepLink == null) return QPayBankLaunchResult.failed;

    final target = _resolveTarget(
      scheme: deepLink.scheme,
      bankName: bank.name,
    );

    if (await _tryLaunch(deepLink)) {
      return QPayBankLaunchResult.openedApp;
    }

    final storeUri = _storeUri(target, bank.name);
    if (storeUri != null && await _tryLaunch(storeUri)) {
      return QPayBankLaunchResult.openedStore;
    }

    return QPayBankLaunchResult.failed;
  }

  static _BankStoreTarget? _resolveTarget({
    required String scheme,
    required String bankName,
  }) {
    final normalizedScheme = scheme.toLowerCase();
    for (final target in _targets) {
      if (target.schemes.contains(normalizedScheme)) {
        return target;
      }
    }

    final normalizedName = _normalize(bankName);
    for (final target in _targets) {
      for (final keyword in target.keywords) {
        if (normalizedName.contains(_normalize(keyword))) {
          return target;
        }
      }
    }

    return null;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9а-яөүё]+'), '');
  }

  static Uri? _storeUri(_BankStoreTarget? target, String bankName) {
    if (kIsWeb) return null;

    if (Platform.isAndroid) {
      final package = target?.androidPackage;
      if (package != null && package.isNotEmpty) {
        return Uri.parse('market://details?id=$package');
      }
      return Uri.parse(
        'https://play.google.com/store/search?q=${Uri.encodeComponent(bankName)}&c=apps',
      );
    }

    if (Platform.isIOS) {
      final appId = target?.iosAppId;
      if (appId != null && appId.isNotEmpty) {
        return Uri.parse('https://apps.apple.com/app/id$appId');
      }
      final searchName = target?.storeSearchName ?? bankName;
      return Uri.parse(
        'https://apps.apple.com/mn/search?term=${Uri.encodeComponent(searchName)}',
      );
    }

    return null;
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (uri.scheme == 'market') {
        final httpsFallback = Uri.parse(
          'https://play.google.com/store/apps/details?id=${uri.queryParameters['id']}',
        );
        try {
          return await launchUrl(
            httpsFallback,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          return false;
        }
      }
      return false;
    }
  }
}
