import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit(
initializerName: 'init', // default
publicRootPath: null, // default is null
preferRelativeImports: true, // default is true
asNewInstance: false, // default is false
)
Future<void> configureDependencies() => init(getIt);