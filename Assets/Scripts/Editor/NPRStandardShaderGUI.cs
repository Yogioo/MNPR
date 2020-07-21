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

        protected MaterialProperty m_MiddleLineStrength;
        protected MaterialProperty m_MiddleLineColor;
        protected MaterialProperty m_FresnelStrength;
        protected MaterialProperty m_FresnelColor;

        private static class CustomStyles
        {
            public static GUIContent CullMode = new GUIContent("Cull Mode");
            public static GUIContent ShadowColor = new GUIContent("Shadow Color");
            public static GUIContent ShadowStrength = new GUIContent("Shadow Strength"); 
            public static GUIContent ReceiveShadowColor = new GUIContent("Receive Shadow Color"); 

            public static GUIContent MiddleLineStrength = new GUIContent("Middle Line Strength");
            public static GUIContent MiddleLineColor = new GUIContent("Middle Line Color");
            public static GUIContent FresnelStrength = new GUIContent("Fresnel Strength"); 
            public static GUIContent FresnelColor = new GUIContent("Fresnel Color"); 
        }

        #endregion 

        public override void FindPropertiesEx(MaterialProperty[] props)
        {
            base.FindPropertiesEx(props);
            m_CullMode = FindProperty("_CullMode", props);
            m_ShadowColor = FindProperty("_ShadowColor", props);
            m_ShadowStrength = FindProperty("_ShadowStrength", props);
            m_ReceiveShadowColor = FindProperty("_ReceiveShadowColor", props);

            m_MiddleLineStrength = FindProperty("_MiddleLineStrength", props);
            m_MiddleLineColor = FindProperty("_MiddleLineColor", props);
            m_FresnelStrength = FindProperty("_FresnelStrength", props);
            m_FresnelColor = FindProperty("_FresnelColor", props);


        }
        public override void DoExtention()
        {
            base.DoExtention();
            m_MaterialEditor.ShaderProperty(m_CullMode, CustomStyles.CullMode.text);
            m_MaterialEditor.ShaderProperty(m_ShadowColor, CustomStyles.ShadowColor.text);
            m_MaterialEditor.ShaderProperty(m_ReceiveShadowColor, CustomStyles.ReceiveShadowColor.text);
            m_MaterialEditor.ShaderProperty(m_MiddleLineColor, CustomStyles.MiddleLineColor.text);
            m_MaterialEditor.ShaderProperty(m_FresnelColor, CustomStyles.FresnelColor.text);

            m_MaterialEditor.ShaderProperty(m_ShadowStrength, CustomStyles.ShadowStrength.text);
            m_MaterialEditor.ShaderProperty(m_MiddleLineStrength, CustomStyles.MiddleLineStrength.text);
            m_MaterialEditor.ShaderProperty(m_FresnelStrength, CustomStyles.FresnelStrength.text);
        }
    }

    internal class GrassShaderGUI: StandardShaderGUIBase
    {
        #region Property

        protected MaterialProperty m_ReceiveShadowColor;
        protected MaterialProperty m_WindDir;
        protected MaterialProperty m_WindStrength;
        protected MaterialProperty m_WindDensity;


        private static class CustomStyles
        {
           
            public static GUIContent ReceiveShadowColor = new GUIContent("Receive Shadow Color");
            public static GUIContent WindDir = new GUIContent("Wind Dir");
            public static GUIContent WindStrength = new GUIContent("Wind Strength");
            public static GUIContent WindDensity = new GUIContent("Wind Density");

        }

        #endregion 

        public override void FindPropertiesEx(MaterialProperty[] props)
        {
            base.FindPropertiesEx(props);
            
            m_ReceiveShadowColor = FindProperty("_ReceiveShadowColor", props);
            m_WindDir = FindProperty("_WindDir", props);
            m_WindStrength = FindProperty("_WindStrength", props); 
             m_WindDensity = FindProperty("_WindDensity", props);




        }
        public override void DoExtention()
        {
            base.DoExtention();

            m_MaterialEditor.ShaderProperty(m_ReceiveShadowColor, CustomStyles.ReceiveShadowColor.text);
            m_MaterialEditor.ShaderProperty(m_WindDir, CustomStyles.WindDir.text);
            m_MaterialEditor.ShaderProperty(m_WindStrength, CustomStyles.WindStrength.text);
            m_MaterialEditor.ShaderProperty(m_WindDensity, CustomStyles.WindDensity.text);

        }
    }
}
