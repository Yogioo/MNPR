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

        protected MaterialProperty m_cullMode;

        private static class CustomStyles
        {
            public static GUIContent CullMode = new GUIContent("Cull Mode");
        }

        #endregion 

        public override void FindPropertiesEx(MaterialProperty[] props)
        {
            base.FindPropertiesEx(props);
            m_cullMode = FindProperty("_CullMode", props);
        }
        public override void DoExtention()
        {
            base.DoExtention();
            m_MaterialEditor.ShaderProperty(m_cullMode, CustomStyles.CullMode.text);
        }
    }
}
