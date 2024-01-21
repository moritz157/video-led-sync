//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import flutter_libserialport
import fvp
import package_info_plus
import screen_retriever
import video_player_avfoundation
import wakelock_plus
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FlutterLibserialportPlugin.register(with: registry.registrar(forPlugin: "FlutterLibserialportPlugin"))
  FvpPlugin.register(with: registry.registrar(forPlugin: "FvpPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
