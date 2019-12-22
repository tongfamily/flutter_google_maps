# ice_cream_stores_demo

Demo based on - [Build Mobile Apps With Flutter and Google Maps](https://www.youtube.com/watch?time_continue=1&v=RpQLFAFqMlw) (Cloud Next '19)

## Important steps to run the project
### 1 - Add api key for google maps services

You'll need to enable google maps services in a google cloud platform project and create an api key to access the services. After that, you'll have to insert your api key in 3 files inside the project (just serch for "api_key_here"). The files are:
- "api_key.dart"
- "ApiKey.m"
- "AndroidManifest.xml"

Make sure not to check your api key into the repo. This is a really bad thing,
so after the initial clone, go to `.gitignore` and uncomment out the lines that
exclude these from the repo.

Also note there are dummy versions which are checked in in case you lose these
files

dummy.api_key.dart
dummy.ApiKey.m
dummy.AndroidManifest.xml

To actually inflate this properly, run `flutter create .` in the directory.

If you've note created an API key before, you need all 11 Google Maps API keys,
so create a google developer account and then go to
https://cloud.google.com/maps-platform/ and it will get you started and give you
an API Key. Make sure to place the key somewhere safe for later access. You want
to make sure the key is restricted to the Google Maps and places api.

               
### 2 - Replicate the cloud firestore database

You'll have to replicate the database and data within Firebase's Cloud Firestore. Cloud Firestore is pretty straightforward and you won't have a hard time replicating the database shown in the demo on youtube, I guess :)

The way you do this is to go to Firebase and create a Firestore database with
the name `ice_cream_stores` then each entry in the system is a document with the
follow fields:

```
address: <Street Address>
location: [37.7"N 32.3"W]
name: <Formal name of the store>
placeID: <The Google Place GUID"
```

Also note that Firestore is a little different in that to connect it, you need
to actually add the Ios and Android application unique identifier into the
Firebase console in the cloud. Then you will get a unique guid to put into your
application. See https://firebase.google.com/docs/flutter/setup

It will want your bundle identifier to change this
https://stackoverflow.com/questions/51534616/how-to-change-package-name-in-flutter
run `flutter create --org <your preferred id> .` if you are doing a new one.

For this existing sample, the package id is just
`com.example.ice_cream_stores_demo` and you can add this to your firebase
console

You need to download the new `google-services.json with a public key in it to
`android/app` 
this file should also be protected as it has the key to access your personal
firebase database on your server. So you want to also make this one a .gitignore

For IOS,
https://stackoverflow.com/questions/51098042/how-to-get-bundle-id-in-flutter#51107491
shows that you want the PRODUCT_BUNDLE_IDENTIFIER in Runner.xcodeproj/pbxproj
which is `com.example.iceCreamStoresDemo` and this gives you a different
`GoogleServices-Info.plist` that you need to copy down

Just in case, here's a screenshot shot of my sample Firestore database:

![ice-cream-stores-demo-firestore](https://user-images.githubusercontent.com/14852938/67521629-a4f14480-f681-11e9-9f78-cb916a2fa8e1.png)

I hope this helps!
