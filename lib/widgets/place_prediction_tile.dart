import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/assistants/request_assistant.dart';
import 'package:riders_app/global/global.dart';
import 'package:riders_app/global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/directions.dart';
import '../models/predicted_places.dart';
import 'progress_dialog.dart';

class PlacePredictionTileDesign extends StatelessWidget {
  final PredictedPlaces? predictedPlace;

  const PlacePredictionTileDesign({Key? key, this.predictedPlace})
      : super(key: key);

  void getPlaceDirectionDetails(String? placeId, BuildContext context) async {
    // https://developers.google.com/maps/documentation/places/web-service/place-id
    // https://developers.google.com/maps/documentation/places/web-service/details#PlaceDetailsResponses
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: 'Setting Up Drof-Off, Please wait...',
      ),
    );

    String placeDirectionDetailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey';

    var responseApi =
        await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);

    Navigator.pop(context);

    if (responseApi == 'Error Occurred, Failed. No Response.') {
      return;
    }

    if (responseApi['status'] == 'OK') {
      Directions directions = Directions();
      directions.locationName = responseApi['result']['name'];
      directions.locationId = placeId;
      directions.locationLatitude =
          responseApi['result']['geometry']['location']['lat'];
      directions.locationLongitude =
          responseApi['result']['geometry']['location']['lng'];

      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocationAddress(directions);

      userDropOffAddress = directions.locationName!;

      Navigator.pop(context, 'obtainedDropoff');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        getPlaceDirectionDetails(predictedPlace!.placeId, context);
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.white24,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            const Icon(
              Icons.add_location,
              color: Colors.grey,
            ),
            const SizedBox(
              width: 14.0,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8.0,
                  ),
                  Text(
                    predictedPlace!.mainText!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(
                    height: 2.0,
                  ),
                  Text(
                    predictedPlace!.secondaryText!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
