using UnityEngine;
using UnityEngine.Networking;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
namespace XSToon
{
    public class XSUpdater : EditorWindow
    {
        [MenuItem("Tools/Xiexe/XSToon/About - Updater")]
        // Use this for initialization
        static public void Init()
        {
            XSUpdater window = EditorWindow.GetWindow<XSUpdater>(true, "XSToon: Docs & Updater", true);
            window.minSize = new Vector2(400, 300);
            window.maxSize = new Vector2(401, 501);
        }

        private static string[] patrons = {};
        private static string path;
        
        static int tab = 0;
        static string updateUrl = "https://api.github.com/repos/Xiexe/Xiexes-Unity-Shaders/releases/latest";
        static string docsURL = "https://docs.google.com/document/d/1xJ4PID_nwqVm_UCsO2c2gEdiEoWoCGeM_GDK_L8-aZE";
        static string patronsURL = "https://raw.githubusercontent.com/Xiexe/thefoxden/master/assets/patronlist/patronlist.txt";
        
        static UnityWebRequest www;
        static string changelog;
        static string publishdate;
        static string curVer;
        static string downloadLink;
        bool hasCalledPatronlist = false;
        static bool showInfo = false;
        Vector2 scrollPos;

        public void OnGUI()
        {
            tab = GUILayout.Toolbar (tab, new string[] {"Documentation", "Updater", "Social"});
             XSStyles.SeparatorThin();
                switch(tab) {
                    case 0:
                        //show Docs from git
                        XSStyles.doLabel("You can find Documentation here.");
                        if(GUILayout.Button("Open Documentation"))
                            Application.OpenURL(docsURL);
        
                    break;

                    case 1: 
                        EditorGUI.BeginChangeCheck();
                            
                            XSStyles.HelpBox("The currently installed version is: v" + XSStyles.ver + "\n\nTo check for updates, use the update button. If you choose to download an update, you will need to manually overwrite the old install by extracting the .zip into the project using the windows explorer. \n\nDo not drag the update directly into Unity - it won't ask to overwrite - it'll just create a duplicate and break.", MessageType.Info);
                            XSStyles.SeparatorThin();
                            if (GUILayout.Button("Check for Updates"))
                            {
                                req(updateUrl);
                                EditorApplication.update += changelogEditorUpdate;
                                showInfo = true;
                            }

                            if(showInfo){
                            
                                scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
                                    Repaint();
                                    XSStyles.doLabelLeft("Newest version: ");
                                    XSStyles.doLabelSmall(curVer);
                                    XSStyles.SeparatorThin();
                                    
                                    XSStyles.doLabelLeft("Release Date: ");
                                    XSStyles.doLabelSmall(publishdate);
                                    XSStyles.SeparatorThin();
                                    
                                    XSStyles.doLabelLeft("Changelog: ");
                                    XSStyles.doLabelSmall(changelog);
                                    
                                EditorGUILayout.EndScrollView();
                                XSStyles.SeparatorThin();
                                if (GUILayout.Button("Download")){
                                    Application.OpenURL(downloadLink);
                                }
                            
                            }
                            else{
                                XSStyles.doLabel("Hit 'Check for Updates' to begin");
                            }
                        EditorGUI.EndChangeCheck();
                       
                    break;

                    case 2:
                        //show Patrons

                        XSStyles.doLabel("Thank you to my patreon supporters, and the people who have helped me along the way, you guys are great!\n Note: You must be in the Discord server to show on this list.");
                        XSStyles.SeparatorThin();
                        XSStyles.doLabel("Current Patrons");
                        XSStyles.SeparatorThin();
                        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
                        if(!hasCalledPatronlist)
                        {      
                            hasCalledPatronlist = true; 
                            req(patronsURL);
                            EditorApplication.update += EditorUpdate;
                        }
                        for(int i = 0; i < patrons.Length; i++)
                        {
                            XSStyles.doLabel(" - " + patrons[i]);
                        }
                        EditorGUILayout.EndScrollView();

                        XSStyles.SeparatorThin();
                        //show social links
                        EditorGUILayout.BeginHorizontal();
                        GUILayout.FlexibleSpace();
                            XSStyles.discordButton(70, 30);
                            XSStyles.patreonButton(70, 30);
                            XSStyles.githubButton(70, 30);
                        GUILayout.FlexibleSpace();
                        EditorGUILayout.EndHorizontal();
                    break;
                }
            
           
        }

        static void req(string url)
        {
            www = UnityWebRequest.Get(url);
            www.SendWebRequest();
            //Debug.Log("Checking for updates...");
        }
        static void EditorUpdate()
        {
            while (!www.isDone)
                return;

            if (www.isNetworkError)
                Debug.Log(www.error);
            else
            {
               patrons = www.downloadHandler.text.Split('\n');
               Debug.Log("Fetching Patron list of: " + patrons.Length);
            }       
            EditorApplication.update -= EditorUpdate;
        }

        static void updateHandler(string apiResult)
        {
            gitAPI git = JsonUtility.FromJson<gitAPI>(apiResult);
                bool option = EditorUtility.DisplayDialog("XSToon: Updater",
                                            "You are on version: \nv" + XSStyles.ver + "\n\nThe latest version is: \n" + git.tag_name + "\n\n You can view the changelog either on my Discord, or at the Github page for this release." + "\n\nWould you like to update?",
                                            "Download", "Cancel");

                switch (option)
                {
                    case true:
                        Application.OpenURL(git.zipball_url);
                        break;

                    case false:
                        Debug.Log("Cancelled Update.");
                        break;
                }
          //  Debug.Log(apiResult);
        }

        static void changelogEditorUpdate()
        {
            while (!www.isDone)
                return;

            if (www.isNetworkError)
                Debug.Log(www.error);
            else
                fetchChangelog(www.downloadHandler.text);
                
            EditorApplication.update -= changelogEditorUpdate;
        }

        static void fetchChangelog(string apiResult)
        {
            gitAPI git = JsonUtility.FromJson<gitAPI>(apiResult);
            
            publishdate = git.published_at;
            curVer = git.tag_name;
            changelog = git.body;
            downloadLink = git.zipball_url;
            //oldChangelog = 
               
               // Debug.Log(git.body);
               // Debug.Log(apiResult);
                // Debug.Log(git.tag_name);
                // Debug.Log(git.html_url);
                // Debug.Log(git.published_at);
                // Debug.Log(git.zipball_url);
                // Debug.Log(git.body);
               
        }

        public class gitAPI
        {
            public string name;
            public string tag_name;
            public string html_url;
            public string published_at;
            public string zipball_url;
            public string body;
        }

    }
}