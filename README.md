# ProjectLoca
Offline AR Language Learning

Project loca uses a local computer vision neural net and dictionary for real-time offline identification and translation of objects.

The camera identifies objects, and the name of the object is translated for the user.

# Limitations

Project loca can only recognize 1000 unique objects and can translate into only one language.

We chose to use this limited, native neural net over Google's Vision API because we wanted ProjectLoca to have full offline capabilities. Offline functionality is especially important for international travel when internet connection is expensive or nonexistent. The number of languages supported by Project Loca could also be significantly increased with the Google Translate API, but again, this would require frequent api calls. 

