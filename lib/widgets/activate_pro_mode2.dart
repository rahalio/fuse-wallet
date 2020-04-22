import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localdolarmx/models/app_state.dart';
import 'package:localdolarmx/screens/routes.gr.dart';
import 'package:localdolarmx/screens/send/send_amount_arguments.dart';
import 'package:localdolarmx/widgets/activate_pro_mode.dart';
import 'dart:core';

import 'package:localdolarmx/widgets/primary_button.dart';

class ActivateProMode2Dialog extends StatefulWidget {
  @override
  createState() => new ActivateProMode2DialogState();
}

class ActivateProMode2DialogState extends State<ActivateProMode2Dialog>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> opacityAnimation;
  Animation<double> scaleAnimatoin;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    opacityAnimation = Tween<double>(begin: 0.0, end: 0.4).animate(
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn));
    scaleAnimatoin =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      setState(() {});
    });

    controller.forward();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: scaleAnimatoin,
        child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            content: Stack(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/images/vi_sign_2.svg',
                        fit: BoxFit.fill,
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                      ),
                      const SizedBox(height: 20.0),
                      Text("Pro mode activated successfully!",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.normal)),
                      const SizedBox(height: 20.0),
                      Text(
                          "You can access it by clicking\n “Pro mode” on the sidebar menu",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.normal)),
                      const SizedBox(height: 20.0),
                      new StoreConnector<AppState, ActivateProModeViewModel>(
                          distinct: true,
                          converter: ActivateProModeViewModel.fromStore,
                          builder: (_, viewModel) {
                            return Center(
                                child: PrimaryButton(
                              labelFontWeight: FontWeight.normal,
                              label: 'Choose amount to transfer',
                              fontSize: 15,
                              onPressed: () {
                                Router.navigator.pushNamed(
                                    Router.sendAmountScreen,
                                    arguments: SendAmountArguments(
                                        sendType: SendType.FUSE_ADDRESS,
                                        accountAddress: viewModel
                                            .daiPointsHomeBridgeAddress));
                              },
                            ));
                          })
                    ],
                  ),
                )
              ],
            )));
    // });
  }
}