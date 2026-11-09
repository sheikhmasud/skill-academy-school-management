# Skill Academy — School Management System

**Founder:** Md. Masud Rana  
**Platforms:** Android and Web  
**Framework:** Flutter  
**Storage in this starter version:** Local device/browser storage using `shared_preferences`

## Included modules

- Dashboard
- Student records (add, edit, delete, search)
- Teacher records (add, edit, delete, search)
- Attendance records (add, edit, delete, search)
- Fee payment records (add, edit, delete, search)
- Examination records (add, edit, delete, search)
- Notice board (add, edit, delete, search)
- Basic reports
- Institution settings

## Important limitation

This is a working starter/MVP, not yet a production-ready school ERP. Records are stored locally on the current device or browser. They do not automatically sync between Android and Web. There is no secure login, cloud database, role-based access, or cloud backup yet.

Do not enter real student personal information until authentication, database security, and backup are configured.

## Setup on Windows 10

1. Install Flutter SDK, Git, VS Code, and Android Studio.
2. Extract this ZIP file.
3. Open the extracted `skill_academy_school_management` folder in VS Code.
4. Open Terminal in VS Code.
5. Run:

```bash
flutter create .
flutter pub get
```

6. Run the Web version:

```bash
flutter run -d chrome
```

7. To run on an Android phone:
   - Enable Developer options and USB debugging on the phone.
   - Connect the phone to the PC with USB.
   - Run `flutter devices` to check that Flutter detects it.
   - Run:

```bash
flutter run
```

## Build outputs

Web build:

```bash
flutter build web
```

Android APK:

```bash
flutter build apk --release
```

APK output:

`build/app/outputs/flutter-apk/app-release.apk`

## Notes

- The first run may take several minutes while Flutter downloads dependencies.
- `flutter doctor` can help identify missing Android or browser tools.
- For a production release, next add Supabase authentication, cloud database tables, Row Level Security policies, backup, and role permissions (Admin, Teacher, Accountant).


## Publish the Web app on GitHub Pages

This project includes `.github/workflows/deploy-web.yml`.

1. Create a new GitHub repository (for example: `skill-academy-school-management`).
2. Upload the **contents** of this project folder to the repository's `main` branch. Do not upload only the ZIP file.
3. Open the repository's **Settings → Pages**.
4. Under **Build and deployment**, set **Source** to **GitHub Actions**.
5. Open the **Actions** tab. The workflow named **Build and deploy Flutter Web** should start after the push. If it does not, open the workflow and choose **Run workflow**.
6. When the workflow finishes successfully, open **Settings → Pages** to find the published website URL. It will normally look like `https://YOUR-USERNAME.github.io/REPOSITORY-NAME/`.

The workflow generates the Flutter platform folders, builds the web version, and deploys `build/web` to GitHub Pages.

**Important:** GitHub Pages hosts the Web version only. It does not run an Android APK. To create an APK, build it locally with `flutter build apk --release` or add a separate Android build workflow.
