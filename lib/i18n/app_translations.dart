import 'package:get/get_navigation/src/root/internacionalization.dart';

// ignore_for_file: constant_identifier_names

class AppTranslations extends Translations {
  // Define constants (French as base language)
  static const String ServerFailureMessage =
      "Un erreur est survenue, veuillez réessayer plus tard";
  static const String EmptyCacheFailureMessage = "Le cache est vide";
  static const String OfflineFailureMessage =
      "Vous n'êtes pas connecté à internet";
  static const String ForgetPasswordSuccessMessage =
      "Un email de réinitialisation de mot de passe vous a été envoyé";
  static const String PasswordResetedSuccessMessage =
      "Votre mot de passe a été réinitialisé avec succès";
  static const String PasswordChangeSucessMessage =
      "Votre mot de passe a été changé avec succès";
  static const String SignUpSuccessMessage =
      "Inscription réussie, veuillez confirmer votre email puis vous connecter 😊";

  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'title': 'Démo Flutter',
      'server_failure_message': ServerFailureMessage,
      'empty_cache_failure_message': EmptyCacheFailureMessage,
      'offline_failure_message': OfflineFailureMessage,
      'forget_password_success_message': ForgetPasswordSuccessMessage,
      'password_reseted_success_message': PasswordResetedSuccessMessage,
      'password_change_success_message': PasswordChangeSucessMessage,
      'sign_up_success_message': SignUpSuccessMessage,
      'unauthorized_failure_message': "Vous n'êtes pas autorisé",
      'unexpected_error_message': "Une erreur inattendue s'est produite",
      'explore_now': "Explorer maintenant",
      // Login page strings
      'login_title': "Connexion",
      'email_label': "Adresse e-mail",
      'email_hint': "Entrez votre e-mail",
      'password_label': "Mot de passe",
      'name_label': "Nom",
      'name_hint': "Entrez votre nom",
      'password_hint': "Entrez votre mot de passe",
      'login_button': "Se connecter",
      'forgot_password': "Mot de passe oublié ?",
      'no_account': "Vous n'avez pas encore de compte ?",
      'sign_up_link': "Inscrivez-vous",
      'invalid_credentials': "E-mail ou mot de passe incorrect",
      'empty_field_error': "Ce champ ne peut pas être vide",
      'invalid_email_error': "Adresse e-mail invalide",
      'confirm_password_hint': "Confirmez votre mot de passe",
      'confirm_password_label': "Confirmez le mot de passe",
      'have_account': "Vous avez déjà un compte ?",
    },
    'ar_AR': {
      'title': 'عرض Flutter',
      'server_failure_message': "حدث خطأ، يرجى المحاولة مرة أخرى لاحقًا",
      'empty_cache_failure_message': "الذاكرة المؤقتة فارغة",
      'offline_failure_message': "أنت غير متصل بالإنترنت",
      'forget_password_success_message':
          "تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور إليك",
      'password_reseted_success_message':
          "تم إعادة تعيين كلمة المرور الخاصة بك بنجاح",
      'password_change_success_message': "تم تغيير كلمة المرور الخاصة بك بنجاح",
      'sign_up_success_message':
          "نجحت عملية التسجيل، يرجى تأكيد بريدك الإلكتروني ثم تسجيل الدخول 😊",
      'unauthorized_failure_message': "غير مصرح لك",
      'unexpected_error_message': "حدث خطأ غير متوقع",
      'explore_now': "استكشف الآن",
      // Login page strings
      'login_title': "تسجيل الدخول",
      'email_label': "البريد الإلكتروني",
      'email_hint': "أدخل بريدك الإلكتروني",
      'name_label': "الاسم",
      'name_hint': "أدخل اسمك",
      'password_label': "كلمة المرور",
      'password_hint': "أدخل كلمة المرور",
      'login_button': "تسجيل الدخول",
      'forgot_password': "نسيت كلمة المرور؟",
      'no_account': "ليس لديك حساب؟",
      'sign_up_link': "اشترك",
      'invalid_credentials': "البريد الإلكتروني أو كلمة المرور غير صحيحة",
      'empty_field_error': "هذا الحقل لا يمكن أن يكون فارغًا",
      'invalid_email_error': "عنوان بريد إلكتروني غير صالح",
      'confirm_password_hint': "تأكيد كلمة المرور",
      'confirm_password_label': "تأكيد كلمة المرور",
      'have_account': "هل لديك حساب بالفعل؟",
    },
    'en_US': {
      'title': 'Flutter Demo',
      'server_failure_message': "An error occurred, please try again later",
      'empty_cache_failure_message': "The cache is empty",
      'offline_failure_message': "You are not connected to the internet",
      'forget_password_success_message':
          "A password reset email has been sent to you",
      'password_reseted_success_message':
          "Your password has been successfully reset",
      'password_change_success_message':
          "Your password has been successfully changed",
      'sign_up_success_message':
          "Sign-up successful, please confirm your email and log in 😊",
      'unauthorized_failure_message': "You are not authorized",
      'unexpected_error_message': "An unexpected error occurred",
      'explore_now': "Explore Now",
      // Login page strings
      'login_title': "Login",
      'email_label': "Email Address",
      'email_hint': "Enter your email",
      'name_label': "Name",
      'name_hint': "Enter your name",
      'password_label': "Password",
      'password_hint': "Enter your password",
      'login_button': "Log In",
      'forgot_password': "Forgot Password?",
      'no_account': "Don't have an account?",
      'sign_up_link': "Sign Up",
      'invalid_credentials': "Incorrect email or password",
      'empty_field_error': "This field cannot be empty",
      'invalid_email_error': "Invalid email address",
      'confirm_password_hint': "Confirm your password",
      'confirm_password_label': "Confirm Password",
      'have_account': "Already have an account?",
    },
  };
}
