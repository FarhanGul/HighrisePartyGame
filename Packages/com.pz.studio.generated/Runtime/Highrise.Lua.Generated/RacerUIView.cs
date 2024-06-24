/*

    Copyright (c) 2024 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/RacerUIView")]
    [LuaBehaviourScript(s_scriptGUID)]
    public class RacerUIView : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "9083001c57023b446b2a0298bccf8345";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public Highrise.Client.TapHandler m_playTapHandler = default;
        [SerializeField] public UnityEngine.GameObject m_playPressedGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_audioManagerGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_player01Hud = default;
        [SerializeField] public UnityEngine.GameObject m_player02Hud = default;
        [SerializeField] public UnityEngine.GameObject m_turnGenericTextGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_actionMessageGenericTextGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_actionHelpGenericTextGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_actionPanelGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_resultPanelGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_resultGenericTextGameObject = default;
        [SerializeField] public Highrise.Client.TapHandler m_resultContinueTapHandler = default;
        [SerializeField] public UnityEngine.GameObject m_playGameHandlerGameObject = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_playTapHandler),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_playPressedGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_audioManagerGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_player01Hud),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_player02Hud),
                CreateSerializedProperty(_script.GetPropertyAt(5), m_turnGenericTextGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(6), m_actionMessageGenericTextGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(7), m_actionHelpGenericTextGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(8), m_actionPanelGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(9), m_resultPanelGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(10), m_resultGenericTextGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(11), m_resultContinueTapHandler),
                CreateSerializedProperty(_script.GetPropertyAt(12), m_playGameHandlerGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(13), null),
            };
        }
    }
}

#endif
