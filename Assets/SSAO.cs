using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSAO : MonoBehaviour {

	public Material material;

	private const int NUM_RANDOM_DIRECTIONS = 100;

	private int inverseProjectionMatrixID;
	private int inverseViewMatrixID;
	private int projectionMatrixID;
	private int viewMatrixID;
	private int randomDirectionsID;

	private Vector4[] randomDirections;

	private void Awake() {
		Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;

		inverseProjectionMatrixID = Shader.PropertyToID ("_InverseProjectionMatrix");
		inverseViewMatrixID = Shader.PropertyToID ("_InverseViewMatrix");
		projectionMatrixID = Shader.PropertyToID ("_ProjectionMatrix");
		viewMatrixID = Shader.PropertyToID ("_ViewMatrix");
		randomDirectionsID = Shader.PropertyToID ("_RandomDirections");

		randomDirections = new Vector4[NUM_RANDOM_DIRECTIONS];

		for (int i = 0; i < NUM_RANDOM_DIRECTIONS; i++) {
			float x = Random.Range (-1.0f, 1.0f);
			float y = Random.Range (-1.0f, 1.0f);
			float z = Random.Range (-1.0f, 1.0f);

			Vector4 randomDirection = new Vector4 (x, y, z, 0.0f);
			randomDirection.Normalize ();

			randomDirections [i] = randomDirection;
		}

		material.SetVectorArray (randomDirectionsID, randomDirections);
	}

	private void Update() {
		material.SetMatrix (inverseProjectionMatrixID, Camera.main.projectionMatrix.inverse);
		material.SetMatrix (inverseViewMatrixID, Camera.main.cameraToWorldMatrix);
		material.SetMatrix (projectionMatrixID, Camera.main.projectionMatrix);
		material.SetMatrix (viewMatrixID, Camera.main.worldToCameraMatrix);
	}

	private void OnRenderImage(RenderTexture src, RenderTexture dest) {
		Graphics.Blit(src, dest, material);
	}

}
