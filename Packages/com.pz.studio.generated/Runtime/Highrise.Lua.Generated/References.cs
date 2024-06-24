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
    [AddComponentMenu("Lua/References")]
    [LuaBehaviourScript(s_scriptGUID)]
    public class References : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "dd1eecc9cad72424e90bbbf48b4b6257";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public UnityEngine.GameObject m_matchmakerGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_cardManagerGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_audioManagerGameObject = default;
        [SerializeField] public UnityEngine.GameObject m_racerUIViewGameObject = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_matchmakerGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_cardManagerGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_audioManagerGameObject),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_racerUIViewGameObject),
            };
        }
    }
}

#endif