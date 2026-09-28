package de.appgewaltig.disk_space

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class DiskSpacePlugin: FlutterPlugin {

  companion object {
    private var channel: MethodChannel? = null
    private var handler: MethodHandlerImpl = MethodHandlerImpl()

    private fun registerChannel(messenger: BinaryMessenger) {
      channel = MethodChannel(messenger, "disk_space")
      channel!!.setMethodCallHandler(handler)
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    registerChannel(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = null
  }
}