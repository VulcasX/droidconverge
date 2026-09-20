package org.droidconverge.bridge;

import android.view.InputDevice;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/** Root app_process entry point. No upstream implementation is copied. */
public final class InputRouterShell {
    private static Object inputService() throws Exception {
        Class<?> manager = Class.forName("android.os.ServiceManager");
        Object binder = manager.getMethod("getService", String.class).invoke(null, "input");
        Class<?> stub = Class.forName("android.hardware.input.IInputManager$Stub");
        return stub.getMethod("asInterface", Class.forName("android.os.IBinder"))
                .invoke(null, binder);
    }

    private static String displayUniqueId(int id) throws Exception {
        Class<?> global = Class.forName("android.hardware.display.DisplayManagerGlobal");
        Object instance = global.getMethod("getInstance").invoke(null);
        Object info = global.getMethod("getDisplayInfo", int.class).invoke(instance, id);
        if (info == null) throw new IllegalArgumentException("Display disconnected");
        Field uniqueId = info.getClass().getField("uniqueId");
        String value = (String) uniqueId.get(info);
        if (value == null || !value.startsWith("local:"))
            throw new IllegalArgumentException("Only physical local displays are supported");
        return value;
    }

    private static InputDevice externalInput(int id) {
        InputDevice device = InputDevice.getDevice(id);
        if (device == null || device.isVirtual() || !device.isExternal())
            throw new IllegalArgumentException("External input device unavailable");
        int sources = device.getSources();
        if ((sources & InputDevice.SOURCE_MOUSE) != InputDevice.SOURCE_MOUSE
                && (sources & InputDevice.SOURCE_KEYBOARD) != InputDevice.SOURCE_KEYBOARD)
            throw new IllegalArgumentException("Device is not a keyboard or mouse");
        return device;
    }

    public static void main(String[] args) {
        try {
            if (args.length == 1 && "list".equals(args[0])) {
                for (int id : InputDevice.getDeviceIds()) {
                    InputDevice device = InputDevice.getDevice(id);
                    if (device != null && device.isExternal())
                        System.out.println(id + "\t" + device.getName() + "\t" + device.getDescriptor());
                }
                return;
            }
            boolean route = args.length == 3 && "route".equals(args[0]);
            boolean restore = args.length == 2 && "restore".equals(args[0]);
            if (!route && !restore)
                throw new IllegalArgumentException("Usage: list | route DEVICE_ID DISPLAY_ID | restore DESCRIPTOR");
            Object service = inputService();
            if (route) {
                int deviceId = Integer.parseInt(args[1]);
                int displayId = Integer.parseInt(args[2]);
                InputDevice device = externalInput(deviceId);
                if (displayId == 0) throw new IllegalArgumentException("Use restore for tablet display");
                String display = displayUniqueId(displayId);
                String descriptor = device.getDescriptor();
                Method method = service.getClass().getMethod("addUniqueIdAssociationByDescriptor",
                        String.class, String.class);
                method.invoke(service, descriptor, display);
                System.out.println("OK route " + descriptor + " " + display);
            } else {
                String descriptor = args[1];
                if (!descriptor.matches("[a-fA-F0-9]{40}"))
                    throw new IllegalArgumentException("Invalid input descriptor");
                Method method = service.getClass().getMethod("addUniqueIdAssociationByDescriptor",
                        String.class, String.class);
                String display = displayUniqueId(0);
                method.invoke(service, descriptor, display);
                System.out.println("OK restore " + descriptor + " " + display);
            }
        } catch (Exception e) {
            System.err.println("ERROR " + e.getClass().getSimpleName() + ": " + e.getMessage());
            System.exit(1);
        }
    }
}
