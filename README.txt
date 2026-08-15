CSE 489 - Lab Exam
Smart Geo-Tagged Landmarks

Student ID: 22201670
Made with Flutter (Dart) for Android
API key is set in app/lib/api.dart


1. PROJECT OVERVIEW
-------------------------------------------------------------------
An Android app that uses the API given by the faculty. You can see
landmarks in a list and on a map, visit them, add new ones, and
delete or restore them.

The app saves everything in a small database on the phone. The
screens read from that database, not from the internet. So the app
still works when there is no internet.

Files:

    app/lib/main.dart             starts the app
    app/lib/models.dart           the data classes
    app/lib/api.dart              all the API calls
    app/lib/database.dart         the SQLite tables
    app/lib/repository.dart       connects API and database
    app/lib/background_sync.dart  the WorkManager part
    app/lib/app_state.dart        shared data for the screens
    app/lib/ui/                   the 4 tabs


2. FEATURES IMPLEMENTED
-------------------------------------------------------------------
1.  Shows all landmarks with title, image and score.
2.  Map of Bangladesh with a pin for each landmark. Pin colour is
    red for low score and green for high score. Tap a pin to see
    the details.
3.  Visit button. It takes your GPS location, sends the visit, and
    shows the distance when the server is finished.
4.  List with sorting by score and filtering by minimum score.
5.  Activity tab with the visit history: name, time and distance.
6.  Add tab to make a new landmark. The GPS is filled automatically
    and you can add a picture.
7.  Delete a landmark, and restore it again from the Add tab.
8.  Works offline. Old data is still shown, and visits are saved and
    sent later.
9.  Snackbar for success and a dialog box for errors.
10. WorkManager does the background work.

The app has 4 tabs at the bottom: Map, Landmarks, Activity, Add/View.


3. API USAGE
-------------------------------------------------------------------
All API code is in app/lib/api.dart.
Every request needs ?key=22201670, or the API gives error 403.

    get_landmarks     GET    gives the list of landmarks
    get_job_status    GET    tells if a visit is finished
    visit_landmark    POST   body is JSON, gives back a job_id
    create_landmark   POST   body is multipart/form-data
    delete_landmark   POST   body is x-www-form-urlencoded
    restore_landmark  POST   body is x-www-form-urlencoded

create_landmark must be multipart. If you send JSON the image does
not get saved on the server.


4. OFFLINE STRATEGY
-------------------------------------------------------------------
I use SQLite with the sqflite package. There are 3 tables:

    landmarks          copy of the landmarks from the API
    visits             the visit queue and the visit history
    deleted_landmarks  what I deleted, so I can restore it

The screens always read from SQLite, so they work without internet.

When you press Visit, the visit is first saved in the database with
the status "queued". Then WorkManager sends it. This happens the
same way online and offline.

I use connectivity_plus to see when the internet comes back. Then
WorkManager sends everything that is still in the queue.


5. ARCHITECTURE USED
-------------------------------------------------------------------
I used the Repository pattern.

    the 4 screens
         |
    AppState  (provider package)
         |
    LandmarkRepository -----> LandmarkApi (internet)
         |
         +-----------------> AppDatabase (SQLite)

The screens do not talk to the API. They only talk to AppState.

Background work (app/lib/background_sync.dart):

The API does not give the distance immediately. It gives a job_id
and you have to check get_job_status again and again until it says
"done".

The assignment does not allow a normal Thread or Timer loop, so I
used WorkManager. My function syncVisits() does 2 things:

    1. sends the visits that are still "queued"
    2. checks the jobs that are "pending" and saves the distance

If there is still work left, the function returns false. WorkManager
then runs it again later with a longer delay each time. So the retry
is the loop. It also keeps working if the app is closed.

Packages used: http, sqflite, path, workmanager, connectivity_plus,
geolocator, image_picker, flutter_map, latlong2, provider.


6. CHALLENGES FACED
-------------------------------------------------------------------
1. The visit does not give the distance immediately.
   It only gives a job_id, so one visit has 3 states over time. I
   solved it by saving the visit in the database with a status
   (queued, pending, done) instead of just calling the API.

2. The image was not uploading.
   I sent the landmark as JSON first. The landmark was created but
   the image was missing and there was no error. I changed it to
   multipart/form-data and then it worked.

3. The emulator GPS is not real.
   The emulator says you are in California, so my first visit gave a
   distance of 12,000 km. I had to change the emulator location to
   Dhaka.


7. HOW TO RUN
-------------------------------------------------------------------
Open the "app" folder in Android Studio, not the outer folder.

    cd app
    flutter pub get
    flutter run

Needs Android 7.0 (API 24) or higher. Allow the location permission
when it asks. The map uses OpenStreetMap so no Google Maps key is
needed.
