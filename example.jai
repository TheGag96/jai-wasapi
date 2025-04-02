main :: () {
    CoInitializeEx(null, xx (COINIT_MULTITHREADED | COINIT_DISABLE_OLE1DDE));

    ///////////////////////////////////////////////////////////////////////////////////////////////

    deviceEnumerator: *IMMDeviceEnumerator;

    guid_MMDeviceEnumerator  := uid(MMDeviceEnumerator.uuid);
    guid_IMMDeviceEnumerator := uid(IMMDeviceEnumerator.uuid);
    guid_IAudioClient3       := uid(IAudioClient3.uuid);
    guid_IAudioRenderClient  := uid(IAudioRenderClient.uuid);

    CoCreateInstance(*guid_MMDeviceEnumerator, null, CLSCTX_INPROC_SERVER, *guid_IMMDeviceEnumerator, cast(**void)(*deviceEnumerator));

    ///////////////////////////////////////////////////////////////////////////////////////////////

    audioDevice: *IMMDevice;

    deviceEnumerator.GetDefaultAudioEndpoint(deviceEnumerator, .eRender, .eConsole, *audioDevice);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    audioClient: *IAudioClient3;

    audioDevice.Activate(audioDevice, *guid_IAudioClient3, xx CLSCTX_INPROC_SERVER, null, cast(**void)(*audioClient));

    ///////////////////////////////////////////////////////////////////////////////////////////////

    defaultPeriod: REFERENCE_TIME;
    minimumPeriod: REFERENCE_TIME;

    audioClient.GetDevicePeriod(audioClient, *defaultPeriod, *minimumPeriod);

    mixFormat: *WAVEFORMATEX;

    audioClient.GetMixFormat(audioClient, *mixFormat);

    audioClient.Initialize(audioClient, .SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK, minimumPeriod, 0, mixFormat, null);

    audioRenderClient: *IAudioRenderClient;

    audioClient.GetService(audioClient, *guid_IAudioRenderClient, cast(**void)(*audioRenderClient));

    bufferSize: u32;

    audioClient.GetBufferSize(audioClient, *bufferSize);

    bufferReady := CreateEventA(null, xx false, xx false, null);

    audioClient.SetEventHandle(audioClient, bufferReady);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    time: float64 = 0.0;

    audioClient.Start(audioClient);

    while WaitForSingleObject(bufferReady, INFINITE) == WAIT_OBJECT_0 {
        bufferPadding: u32;

        audioClient.GetCurrentPadding(audioClient, *bufferPadding);

        frameCount: int = bufferSize - bufferPadding;
        buffer: *float;

        audioRenderClient.GetBuffer(audioRenderClient, xx frameCount, cast(**u8)(*buffer));

        for frameIndex: 0..frameCount-1 {
            amplitude := 0.2 * cast(float)(sin(time));

            buffer.* = amplitude; // left
            buffer += 1;
            buffer.* = amplitude; // right
            buffer += 1;

            time += 0.05;
        }

        audioRenderClient.ReleaseBuffer(audioRenderClient, xx frameCount, 0);
    }

    audioClient.Stop(audioClient);
}

#load "module.jai";  // #import "WASAPI";

#import "Basic";
#import "Math";
#import "Windows";
#import "Windows_Resources";