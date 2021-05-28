using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
namespace XSToon3
{
    public class XSReimportMyShadersPlease : AssetPostprocessor
    {
        private static string xsFilePath = null;
        static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
        {
            if (xsFilePath == null)
            {
                xsFilePath = XSStyles.findAssetPath("");
            }
            foreach (string str in importedAssets)
            {
                if (str.StartsWith(xsFilePath + "/Main/CGIncludes"))
                {
                    Debug.Log("XS CGInclude updated: " + str.Replace(xsFilePath + "/Main/CGIncludes/",""));
                    string[] files = Directory.GetFiles(xsFilePath + "/Main/Shaders", "*.shader");
                    foreach (string file in files)
                    {
                        AssetDatabase.ImportAsset(file, ImportAssetOptions.ForceUpdate);
                    }
                }

                if (str.StartsWith(xsFilePath + "/Main/Patreon/CGIncludes"))
                {
                    Debug.Log("XS CGInclude updated: " + str.Replace(xsFilePath + "/Main/Patreon/CGIncludes/",""));
                    string[] files = Directory.GetFiles(xsFilePath + "/Main/Patreon/Shaders", "*.shader");
                    foreach (string file in files)
                    {
                        AssetDatabase.ImportAsset(file, ImportAssetOptions.ForceUpdate);
                    }
                }

            }
        }
    }
}