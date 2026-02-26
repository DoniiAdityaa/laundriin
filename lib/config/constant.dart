const String productionPackageName = "com.example.learning_japanese";
const String sandboxPackageName = "com.example.learning_japanese";
const String appId = "6740189117";

/// Network Config
const String baseUrlProduction = "https://antifake.id";
const String baseUrlSandbox = "https://antifake.id";
const String baseSocketProduction = 'https://socket.pcctabessmg.xyz';
const String baseSocketSandbox = 'https://socket.pcctabessmg.xyz';
const String baseUrl = isProduction ? baseUrlProduction : baseUrlSandbox;
const String baseSocket =
    isProduction ? baseSocketProduction : baseSocketSandbox;
const String baseApi = baseUrl;
const String baseApiV2 = "$baseUrl/apis/v2";
const String baseImage = "$baseUrl/images/products/";
const String path_slider = "$baseUrl/images/sliders/";
const String firebaseSecondaryApp = "secondary";
const String playStoreUrl =
    'https://play.google.com/store/apps/details?id=$productionPackageName';
const String appStoreUrl =
    'https://apps.apple.com/id/app/urbanstyle/id6740189117';
const String deleteAccountUrl = "https://forms.gle/MAqxWapu3KqSE9eE7";
const String notificationChannelId = "urban_style_default_channel";

const String firebaseDatabaseUrl = "https://creativelabz-c19e0.firebaseio.com/";

/// is production
/// ALWAYS CHANGE THIS VALUE TO TRUE WHEN DEPLOYING TO PRODUCTION
const bool isProduction = false;

/// Int
const int otpVerificationDurationInSeconds = 30;
const int timeOutDuration = 30;
const int successScreenDuration = 3;
const double imageMaxHeight = 720;
const double imageMaxWidth = 720;

const int firebaseOtpVerificationDurationInSeconds = 120;
const int whatsAppOtpVerificationDurationInSeconds = 300;
