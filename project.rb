require "xcodeproj"

# El .xcodeproj se genera con este script en vez de versionarse. La razon es la misma que
# en el repo del SDK: un pbxproj versionado convierte cada archivo agregado en un conflicto
# entre ramas, y QA va a agregar casos.
ROOT = File.expand_path(__dir__)
NAME = "SDKQAAppleTVSPM"
PROJ = File.join(ROOT, "#{NAME}.xcodeproj")

require "fileutils"
FileUtils.rm_rf(PROJ)
project = Xcodeproj::Project.new(PROJ)
target = project.new_target(:application, NAME, :tvos, "15.0")

target.build_configurations.each do |c|
  s = c.build_settings
  s["PRODUCT_BUNDLE_IDENTIFIER"] = "am.mediastre.SDKQAAppleTVSPM"
  s["PRODUCT_NAME"]              = NAME
  s["INFOPLIST_FILE"]            = "#{NAME}/Info.plist"
  s["TVOS_DEPLOYMENT_TARGET"]    = "15.0"
  s["SWIFT_VERSION"]             = "5.0"
  s["DEVELOPMENT_TEAM"]          = "36JC5PX87S"
  s["CODE_SIGN_STYLE"]           = "Automatic"
  s["TARGETED_DEVICE_FAMILY"]    = "3"
  s["GENERATE_INFOPLIST_FILE"]   = "NO"
  s["ASSETCATALOG_COMPILER_APPICON_NAME"] = "App Icon & Top Shelf Image"
  s["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = c.name == "Debug" ? "DEBUG" : ""
end

group = project.new_group(NAME, NAME, :group)

sources = Dir.glob(File.join(ROOT, NAME, "*.swift")).sort
abort "ERROR: no hay fuentes en #{NAME}/" if sources.empty?
sources.each { |p| target.add_file_references([group.new_file(File.basename(p))]) }
puts "fuentes: #{sources.count}"

target.add_resources([group.new_file("Assets.xcassets")])
group.new_file("Info.plist")

# Dependencia remota al repo de distribucion, no a un path local: esta app tiene que
# resolver el paquete igual que lo hace un cliente. Si el paquete no resuelve desde
# GitHub, aca se ve.
pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
pkg.repositoryURL = "https://github.com/mediastream/MediastreamPlatformSDKAppleTV-spm.git"
pkg.requirement   = { "kind" => "exactVersion", "version" => "2.1.0-dev.2" }
project.root_object.package_references << pkg

dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
dep.package      = pkg
dep.product_name = "MediastreamPlatformSDKAppleTV"
target.package_product_dependencies << dep

bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
bf.product_ref = dep
target.frameworks_build_phase.files << bf

project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJ, NAME, true)
puts "proyecto generado: #{PROJ}"
