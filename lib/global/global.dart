import 'package:firebase_auth/firebase_auth.dart';
import 'package:riders_app/models/direction_details_info.dart';
import 'package:riders_app/models/user_model.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
UserModel? userModelCurrentInfo;
List dList = []; // online-active drivers info list
DirectionDetailsInfo? tripDirectionDetailsInfo;
String? chosenDriverId = '';
String cloudMessagingServerToken =
    'key=AAAAXbeem1Y:APA91bE0GbXJitRsRW_W_nlPw1eXZxiiWPTUCFwQrQCfB02sQdgujFhkCyu9OmnHmsaf07yP042FvUkmpDXj-se3aozjhWZ3RqR_sxHlhbA4UKk2-4wksZiDqliyNOQkewcBwNiMRoOT';
String userDropOffAddress = '';
String driverCarDetails = '';
String driverName = '';
String driverPhone = '';

double countRatingStars = 0.0;
String titleStarsRating = '';
