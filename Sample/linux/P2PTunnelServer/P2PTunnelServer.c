#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <pthread.h>
#include <sys/wait.h>
#include "P2PTunnelAPIs.h"

/* Customized connect error code */
#define ER_AUTH_DATA_NOT_SET -777
#define ER_AUTH_DATA_IS_WRONG -888

/* Customized connect account & password */
#define USERNAME "Tutk.com"
#define PASSWORD "P2P Platform"

typedef struct st_AuthData
{
    char szUsername[64];
    char szPassword[64];
} sAuthData;

/* Thread for checking Last IO time */
void *thread_ForCheckLastIOTime(void *arg)
{
    int SID = *(int *)arg;
    free(arg);

    printf("[thread_ForCheckLastIOTime] Thread starts at IOTC Session[%d]\n", SID);

    while(1)
    {
        /* To get the last IO time based on the IOTC session */
        int access_time = P2PTunnel_LastIOTime(SID);
        if(access_time < 0)
        {
            printf("P2PTunnel_LastIOTime \t[Failure]\t ErrCode[%d]\n", access_time);
            break;        
        }
        else
        {
            printf("P2PTunnel_LastIOTime \t[Success]\t LastIOTime[%d]\n", access_time);
            fflush(stdout);
        }
        sleep(10);
    }

    printf("[thread_ForCheckLastIOTime] Thread ends at IOTC Session[%d]\n", SID);
    
    pthread_exit(0);
}

/* The call back function of P2PTunnelServer_GetStatus, 
   Application can check the connection status from this function */
void TunnelStatusCB(int nErrorCode, int nSID, void *pArg)
{
    /* Do NOT call any P2PTunnelAPI, it may cause dead lock */
    if(nErrorCode == TUNNEL_ER_DISCONNECTED)
    {
        printf("SID[%d] TUNNEL_ER_DISCONNECTED Log file here!\n", nSID);

        if(pArg != NULL)
        {
            printf("MyArg = %s\n", (char *)pArg);
        }
    }
}

/* The call back function of P2PTunnelServer_GetSessionInfo, 
   The P2PTunnelServer can check information of incoming client */ 
int TunnelSessionInfoCB(sP2PTunnelSessionInfo *sSessionInfo, void *pArg)
{
    printf("TunnelSessionInfoCB has been triggered\n");

    if(pArg != NULL) 
    {
        printf("\tpArg = %s\n", (char *)pArg);
    }

    printf("[Client Session Info]\n");
    printf("\tConnection Mode = %d, NAT type = %d\n", sSessionInfo->nMode, sSessionInfo->nNatType);
    printf("\tP2PTunnel Version = %X, SID = %d\n", (unsigned int)sSessionInfo->nVersion, sSessionInfo->nSID);
    printf("\tIP Address = %s:%d\n", sSessionInfo->szRemoteIP, sSessionInfo->nRemotePort);

    /* Make the arguments from client as account and password, 
       and then check if the username and password is correct or not, 
       return a customized error code to the client if there is something wrong */
    if(sSessionInfo->nAuthDataLen == 0 || sSessionInfo->pAuthData == NULL)
    {
        return ER_AUTH_DATA_NOT_SET;
    }
    else if(sSessionInfo->nAuthDataLen > 0)
    {
        sAuthData *pAuthData = (sAuthData *)sSessionInfo->pAuthData;
        printf("  Auth data length = %d, username = %s, passwd = %s\n", sSessionInfo->nAuthDataLen, pAuthData->szUsername, pAuthData->szPassword);
        if(strcmp(pAuthData->szUsername, USERNAME) != 0 || strcmp(pAuthData->szPassword, PASSWORD) != 0)
        {
            return ER_AUTH_DATA_IS_WRONG;
        }
    }

    /* Set the buffer size of Tunnel */
    if(P2PTunnel_SetBufSize(sSessionInfo->nSID, 5120000) < 0)
    {
        printf("P2PTunnel_SetBufSize error SID[%d]\n", sSessionInfo->nSID);
    }

    /* Create a thread to check the last IO time */
    pthread_t Thread_ID;
    int *SID = malloc(sizeof(int));
    *SID = sSessionInfo->nSID;
    pthread_create(&Thread_ID, NULL, &thread_ForCheckLastIOTime, (void *)SID);
    pthread_detach(Thread_ID);

    return 0;
}

int main(int argc, char *argv[])
{
    int nErrorCode = 0;
    int ret;
    char UID[21];
    
    // Get UID from command arguments
    if (argc != 2)
    {
        printf("Missing arguments.\n");
        printf("Usage: %s [UID]\n", argv[0]);
        return -1;
    }
    strcpy(UID, argv[1]);

    /* Set the callback function to get the tunnel status */
    char *s = "My arg Pass to the Call back function";
    P2PTunnelServer_GetStatus(TunnelStatusCB, (void *)s);

    /* Get and print the P2PTunnelAPI version number */
    printf("Tunnel Version[%X]\n", P2PTunnel_Version());

    /* Initialize P2PTunnelAPIs */
    ret = P2PTunnelServerInitialize(20);
    if(ret < 0)
    {
        printf("P2PTunnelServerInitialize \t[Failure]\t ErrCode[%d]!\n", ret);
        return -1;
    }
    
    /* Start the P2PTunnelServer */
    nErrorCode = P2PTunnelServer_Start(UID);
    if(nErrorCode < 0)
    {
        printf("P2PTunnelServer_Start \t[Failure]\t ErrCode[%d]!\n", nErrorCode);
        return -1;
    }
    else
    {
        printf("P2PTunnelServer_Start \t[Success]\n");
    }

    /* If you don't want to use authentication mechanism, you can give NULL argument
       P2PTunnelServer_GetSessionInfo(TunnelSessionInfoCB, NULL); */
    ret = P2PTunnelServer_GetSessionInfo(TunnelSessionInfoCB, (void *)s);
    
    while(1)
    {
        sleep(1);
    }
    
    return 0;
}