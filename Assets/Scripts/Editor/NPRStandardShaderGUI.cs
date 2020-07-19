using UnityEditor;
using UnityEngine;

namespace MNPR.MNPREditor
{
    /// <summary>
    /// NPR Shader GUI
    /// </summary>
    internal class NPRStandardShaderGUI : StandardShaderGUIBase
    {
        #region Property

        protected MaterialProperty m_CullMode;
        protected MaterialProperty m_ShadowColor;
        protected MaterialProperty m_ShadowStrength;
        protected MaterialProperty m_ReceiveShadowColor;
        protected MaterialProperty m_ShadowFade;

        protected MaterialProperty m_MiddleLineStrength;
        protected MaterialProperty m_MiddleLineColor;
        protected MaterialProperty m_MiddleLineWidth;

        private static class CustomStyles
        {
            public static GUIContent CullMode = new GUIContent("Cull Mode");
            public static GUIContent ShadowColor = new GUIContent("Shadow Color");
            public static GUIContent ShadowStrength = new GUIContent("Shadow Strength"); 
            public static GUIContent ReceiveShadowColor = new GUIContent("Receive Shadow Color"); 
            public static GUIContent ShadowFade = new GUIContent("Shadow Fade"); 

            public static GUIContent MiddleLineStrength = new GUIContent("Middle Line Strength");
            public static GUIContent MiddleLineColor = new GUIContent("Middle Line Color");
            public static GUIContent MiddleLineWidth = new GUIContent("Middle Line Width"); 
        }

        #endregion 

        public override void FindPropertiesEx(MaterialProperty[] props)
        {
            base.FindPropertiesEx(props);
            m_CullMode = FindProperty("_CullMode", props);
            m_ShadowColor = FindProperty("_ShadowColor", props);
            m_ShadowStrength = FindProperty("_ShadowStrength", props);
            m_ReceiveShadowColor = FindProperty("_ReceiveShadowColor", props);
            m_ShadowFade = FindProperty("_ShadowFade", props);

            m_MiddleLineStrength = FindProperty("_MiddleLineStrength", props);
            m_MiddleLineColor = FindProperty("_MiddleLineColor", props);
            m_MiddleLineWidth = FindProperty("_MiddleLineWidth", props);
            
        }
        public override void DoExtention()
        {
            base.DoExtention();
            m_MaterialEditor.ShaderProperty(m_CullMode, CustomStyles.CullMode.text);
            m_MaterialEditor.ShaderProperty(m_ShadowColor, CustomStyles.ShadowColor.text);
            m_MaterialEditor.ShaderProperty(m_ShadowStrength, CustomStyles.ShadowStrength.text);
            m_MaterialEditor.ShaderProperty(m_ReceiveShadowColor, CustomStyles.ReceiveShadowColor.text);
            m_MaterialEditor.ShaderProperty(m_ShadowFade, CustomStyles.ShadowFade.text);
            
            m_MaterialEditor.ShaderProperty(m_MiddleLineStrength, CustomStyles.MiddleLineStrength.text);
            m_MaterialEditor.ShaderProperty(m_MiddleLineColor, CustomStyles.MiddleLineColor.text);
            m_MaterialEditor.ShaderProperty(m_MiddleLineWidth, CustomStyles.MiddleLineWidth.text);
        }
    }
}
