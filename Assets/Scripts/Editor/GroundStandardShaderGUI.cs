using UnityEditor;
using UnityEngine;

namespace MNPR.MNPREditor
{
    /// <summary>
    /// NPR Shader GUI
    /// </summary>
    internal class GroundStandardShaderGUI : StandardShaderGUIBase
    {
        #region Property

        protected MaterialProperty m_CullMode;
        protected MaterialProperty m_ReceiveShadowColor;


        private static class CustomStyles
        {
            public static GUIContent CullMode = new GUIContent("Cull Mode");
            public static GUIContent ReceiveShadowColor = new GUIContent("Receive Shadow Color"); 
        }

        #endregion 

        public override void FindPropertiesEx(MaterialProperty[] props)
        {
            base.FindPropertiesEx(props);

            m_CullMode = FindProperty("_CullMode", props);
            m_ReceiveShadowColor = FindProperty("_ReceiveShadowColor", props);
        }
        public override void DoExtention(Material mat)
        {
            base.DoExtention(mat);
            m_MaterialEditor.ShaderProperty(m_CullMode, CustomStyles.CullMode.text);
            m_MaterialEditor.ShaderProperty(m_ReceiveShadowColor, CustomStyles.ReceiveShadowColor.text);
            SetKeyword(mat, "_PARALLAXMAP", true);
        }
    }

}
