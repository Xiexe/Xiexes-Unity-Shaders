using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace XSToon3 {
  public partial class FoldoutToggles {
    public bool ShowIridescentFoldout = true;
  }

  public class XSToonIridescentInspector : XSToonInspector {
    private MaterialProperty _Iridescent = null;
    private MaterialProperty _IridescentColor = null;
    private MaterialProperty _IridescentRimPower = null;
    private MaterialProperty _IridescentSamplingPow = null;

    public override void PluginGUI(MaterialEditor materialEditor, Material material)
    {
      DrawIridescentSettings(materialEditor, material);
    }

    private void DrawIridescentSettings(MaterialEditor materialEditor, Material material)
    {
      Foldouts[material].ShowIridescentFoldout =
        XSStyles.ShurikenFoldout("Iridescent", Foldouts[material].ShowIridescentFoldout);
      if (Foldouts[material].ShowIridescentFoldout) {
        materialEditor.TexturePropertySingleLine(
          new GUIContent("Iridescent Ramp", "Color Ramp. Defines the colors fo the iridescence effect."),
          _Iridescent, _IridescentColor);

        if (_Iridescent.textureValue != null)
        {
          string iridescentRamp = AssetDatabase.GetAssetPath(_Iridescent.textureValue);
          TextureImporter ti = (TextureImporter)TextureImporter.GetAtPath(iridescentRamp);
          if (ti.sRGBTexture)
          {
            if (XSStyles.HelpBoxWithButton(new GUIContent("This texture is not marked as Linear.", "This is recommended for the mask"), new GUIContent("Fix Now")))
            {
              ti.sRGBTexture = false;
              AssetDatabase.ImportAsset(iridescentRamp, ImportAssetOptions.ForceUpdate);
              AssetDatabase.Refresh();
            }
          }
        }

        XSStyles.CallGradientEditor(material, "_Iridescent");

        XSStyles.SeparatorThin();

        materialEditor.ShaderProperty(_IridescentRimPower,
          new GUIContent("Rim Power", "Defines the rim darkening of the iridescence effect"));
        materialEditor.ShaderProperty(_IridescentSamplingPow, new GUIContent("Ramp Power", "Defines the scale and repetition of the iridescence effect. Can be negative."));
      }
    }
  }
}
