using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace XSToon3
{
    public partial class FoldoutToggles
    {
        public bool ShowMeshReconstructionOptions = true;
    }

    public class XSToonParticleGeometryMeshReconstructionInspector : XSToonInspector
    {
        private MaterialProperty _MeshVertexCount = null;
        private MaterialProperty _VertexPosUVXTexture = null;
        private MaterialProperty _VertexNormalUVYTexture = null;
        private MaterialProperty _VertexColorTexture = null;
        private MaterialProperty _MeshScale = null;

        public override void PluginGUI(MaterialEditor materialEditor, Material material)
        {
            DrawMeshReconstructionSettings(materialEditor, material);
        }

        private void DrawMeshReconstructionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowMeshReconstructionOptions = XSStyles.ShurikenFoldout("Mesh Reconstruction", Foldouts[material].ShowMeshReconstructionOptions);

            if (Foldouts[material].ShowMeshReconstructionOptions)
            {
                materialEditor.ShaderProperty(_MeshVertexCount, "Vertex Count");
                materialEditor.ShaderProperty(_MeshScale, "Mesh Scale");
                materialEditor.TexturePropertySingleLine(new GUIContent("Mesh Position Data", "Vertex Position Data Texture (RGB: Vertex Positions | A: UVChannel X)"), _VertexPosUVXTexture);
                materialEditor.TexturePropertySingleLine(new GUIContent("Mesh Normal Data", "Vertex Normal Data Texture (RGB: Vertex Positions | A: UVChannel X)"), _VertexNormalUVYTexture);
                materialEditor.TexturePropertySingleLine(new GUIContent("Mesh Color Data", "Vertex Color Data Texture (RGB: Vertex Positions | A: UVChannel X)"), _VertexColorTexture);
            }
        }
    }
}
