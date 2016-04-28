package com.tutk.samples.p2ptunnelagent;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.app.Activity;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.Button;
import android.widget.ListView;

import java.util.ArrayList;
import java.util.List;

import com.tutk.IOTC.P2PTunnelAPIs;
import com.tutk.IOTC.sP2PTunnelSessionInfo;

import java.nio.charset.StandardCharsets;

// The class must implement the P2PTunnel callback interface
public class MainActivity extends Activity implements com.tutk.IOTC.P2PTunnelAPIs.IP2PTunnelCallback {

    final static int MAX_CONNECTION_ALLOWED = 4;
    final static String USERNAME = "Tutk.com";
    final static String PASSWORD = "P2P Platform";
    final static int ER_AUTH_DATA_NOT_SET = -777;
    final static int ER_AUTH_DATA_IS_WRONG = -888;

    P2PTunnelAPIs agent;
    List<String> arr;
    ArrayAdapter<String> adapter;
    int SID = -1;
    int[] MappingIndexList = new int[16];

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Create a instance of P2PTunnelAgent;
        agent = new P2PTunnelAPIs(MainActivity.this);

        // Initialize the P2PTunnelAgent.
        agent.P2PTunnelAgentInitialize(MAX_CONNECTION_ALLOWED);

        // Create instance of adapter and list for ListView
        arr = new ArrayList<String>();
        adapter = new ArrayAdapter(MainActivity.this, android.R.layout.simple_list_item_1, arr);

        // Declare the variables of User Interface.
        final EditText edtUID = (EditText)findViewById(R.id.edtUID);
        final EditText edtLocalPort = (EditText)findViewById(R.id.edtLocalPort);
        final EditText edtRemotePort = (EditText)findViewById(R.id.edtRemotePort);
        final Button btnConnect = (Button)findViewById(R.id.btnConnect);
        final Button btnPortMapping = (Button)findViewById(R.id.btnPortMapping);
        final ListView lstLog = (ListView)findViewById(R.id.lstLog);

        // Disable the PortMapping button
        btnPortMapping.setEnabled(false);

        // Load UID from SharedPreference
        edtUID.setText(loadUID());

        // Link the adapter to the ListView
        lstLog.setAdapter(adapter);

        // Set OnClick listener of Connect Button
        btnConnect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                final String UID = edtUID.getText().toString();

                // Identify the UID
                if (UID.length() != 20) {
                    LOG("Wrong UID input");
                    return;
                }

                // Disable the Connect Button to prevent unnecessary click
                btnConnect.setEnabled(false);

                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        int ret;
                        int[] errFromDevice = new int[1];

                        // Connect to the device.
                        ret = agent.P2PTunnelAgent_Connect(UID, getAuthData(USERNAME, PASSWORD), getAuthDataLength(), errFromDevice);
                        if (ret >= 0) {
                            SID = ret;
                            LOG("P2PTunnelAgent_Connect() success, the SID = " + errFromDevice[0]);

                            // Save UID to SharedPreferences
                            saveUID(UID);

                            // Enable the PortMapping Button in UI thread
                            toggleButton(btnPortMapping, true);
                        } else if (ret == P2PTunnelAPIs.TUNNEL_ER_AUTH_FAILED) {
                            if (errFromDevice[0] == ER_AUTH_DATA_NOT_SET) {
                                LOG("P2PTunnelAgent_Connect() error, the auth Data is not set.");
                            } else if (errFromDevice[0] == ER_AUTH_DATA_IS_WRONG) {
                                LOG("P2PTunnelAgent_Connect() error, the auth data is wrong.");
                            }

                            // Enable the Connect Button in UI thread
                            toggleButton(btnConnect, true);
                        } else {
                            LOG("P2PTunnelAgent_Connect() error, result = " + ret);

                            // Enable the Connect Button in UI thread
                            toggleButton(btnConnect, true);
                        }
                    }
                }).start();
            }
        });

        // Set OnClick listener of Portmapping Button
        btnPortMapping.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (SID >= 0) {
                    if (edtLocalPort.getText().length() == 0 || edtRemotePort.getText().length() == 0) {
                        LOG("Wrong Local or Remote port input");
                        return;
                    }

                    int localPort = Integer.parseInt(edtLocalPort.getText().toString());
                    int remotePort = Integer.parseInt(edtRemotePort.getText().toString());
                    int index = 0;

                    index = agent.P2PTunnelAgent_PortMapping(SID, localPort, remotePort);
                    if (index >= 0) {
                        LOG("P2PTunnelAgent_PortMapping() success, the mapping index = " + index);
                        MappingIndexList[index] = 1;
                    } else {
                        LOG("P2PTunnelAgent_PortMapping() error, result = " + index);
                    }
                } else {
                    LOG("P2PTunnel session has not been established yet");
                    return;
                }
            }
        });

    }

    private int getAuthDataLength() {
        return 128;
    }

    private byte[] getAuthData(String username, String password) {
        /* The authdata structure between device and client:

            typedef struct st_AuthData
            {
                char szUsername[64];
                char szPassword[64];
            } sAuthData;

        */

        byte[] result = new byte[128];
        byte[] acc = username.getBytes(StandardCharsets.US_ASCII);
        byte[] pwd = password.getBytes(StandardCharsets.US_ASCII);

        // copy acc and pwd to result
        System.arraycopy(acc, 0, result, 0, acc.length);
        System.arraycopy(pwd, 0, result, 64, pwd.length);

        return result;
    }

    private void toggleButton(final Button button, final boolean enabled) {
        MainActivity.this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                button.setEnabled(enabled);
            }
        });
    }

    private void LOG(final String text) {

        // We must run this change in UI thread since some caller are from another thread.
        MainActivity.this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                arr.add(0, text);
                adapter.notifyDataSetChanged();
            }
        });
    }

    private void saveUID(String UID) {
        SharedPreferences settings = getSharedPreferences("Preference", 0);
        settings.edit().putString("uid", UID).commit();
    }

    private String loadUID() {
        SharedPreferences settings = getSharedPreferences("Preference", 0);
        String uid = settings.getString("uid", "");
        return uid;
    }

    // The callback function of TunnelStatusChanged
    @Override
    public void onTunnelStatusChanged(int nErrCode, int nSID) {
        if (nErrCode == P2PTunnelAPIs.TUNNEL_ER_DISCONNECTED) {
            LOG(String.format("Callback: P2PTunnel session[%d] disconnected.", nSID));
            SID = -1;

            // Stop PortMapping
            for (int i = 0; i < 16; i++) {
                if (MappingIndexList[i] == 1) {
                    agent.P2PTunnelAgent_StopPortMapping(i);
                    LOG("P2PTunnelAgent_StopPortMapping(" + i + ")");
                    MappingIndexList[i] = 0;
                }
            }

            // Disable the PortMapping Button in UI thread
            Button btnConnect = (Button)findViewById(R.id.btnConnect);
            Button btnPortMapping = (Button)findViewById(R.id.btnPortMapping);
            toggleButton(btnConnect, true);
            toggleButton(btnPortMapping, false);
        }
    }

    // The callback function of TunnelSessionInfoChanged and only be triggered in P2PTunnelServer
    @Override
    public void onTunnelSessionInfoChanged(sP2PTunnelSessionInfo info) {
        LOG(String.format("Callback: P2PTunnel session[%d] created, remote[%s:%d].", info.getSID(), info.getRemoteIP(), info.getRemotePort()));
    }
}
