function Controller() {
  installer.autoRejectMessageBoxes();
  installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);
  installer.setMessageBoxAutomaticAnswer("stopProcessesForUpdates", QMessageBox.Ignore);
  installer.installationFinished.connect(function() {
    gui.clickButton(buttons.NextButton);
  });
  installer.setMessageBoxAutomaticAnswer("cancelInstallation", QMessageBox.Yes);
}

Controller.prototype.IntroductionPageCallback = function() {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.DynamicTargetWidgetCallback = function() {
  var targetDir = installer.environmentVariable("INSTALL_DIR");
  if (targetDir != "") {
    gui.pageWidgetByObjectName("DynamicTargetWidget").targetDirectory.text = targetDir;
  }
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function() {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
  gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function() {
  gui.clickButton(buttons.CommitButton);
}

Controller.prototype.FinishedPageCallback = function() {
  gui.currentPageWidget().RunItCheckBox.setChecked(false);
  gui.clickButton(buttons.FinishButton);
}
