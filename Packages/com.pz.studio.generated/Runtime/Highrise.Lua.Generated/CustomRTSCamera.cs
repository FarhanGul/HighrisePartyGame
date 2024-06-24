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
    [AddComponentMenu("Lua/CustomRTSCamera")]
    [LuaBehaviourScript(s_scriptGUID)]
    public class CustomRTSCamera : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "31820d6376dde984fbb34b37a955f3a4";
        public override string ScriptGUID => s_scriptGUID;

        [Header("Zoom Settings")]
        [SerializeField] public System.Double m_zoom = 15;
        [SerializeField] public System.Double m_zoomMin = 10;
        [SerializeField] public System.Double m_zoomMax = 50;
        [SerializeField] public System.Double m_fov = 30;
        [Header("Defaults")]
        [SerializeField] public System.Double m_pitch = 30;
        [SerializeField] public System.Double m_yaw = 45;
        [SerializeField] public System.Boolean m_centerOnCharacterWhenSpawned = true;
        [SerializeField] public System.Double m_maxPanning = 10;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_zoom),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_zoomMin),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_zoomMax),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_fov),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_pitch),
                CreateSerializedProperty(_script.GetPropertyAt(5), m_yaw),
                CreateSerializedProperty(_script.GetPropertyAt(6), m_centerOnCharacterWhenSpawned),
                CreateSerializedProperty(_script.GetPropertyAt(7), m_maxPanning),
            };
        }
    }
}

#endif
