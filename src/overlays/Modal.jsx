/* This example requires Tailwind CSS v2.0+ */
import { Fragment } from "react";
import { Dialog, Transition } from "@headlessui/react";

export default function Modal({ isShow, type, title, message, confirmation, cancel, handleConfirmation, handleClose }) {
  return (
    <Transition.Root show={isShow} as={Fragment}>
      <Dialog
        as="div"
        static
        className="fixed z-10 inset-0 overflow-y-auto"
        open={isShow}
        onClose={() => handleClose()}
      >
        <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <Transition.Child
            as={Fragment}
            enter="ease-out duration-300"
            enterFrom="opacity-0"
            enterTo="opacity-100"
            leave="ease-in duration-200"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <Dialog.Overlay className="fixed inset-0 bg-black bg-opacity-40 transition-opacity" />
          </Transition.Child>

          {/* This element is to trick the browser into centering the modal contents. */}
          <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <Transition.Child
            as={Fragment}
            enter="ease-out duration-300"
            enterFrom="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            enterTo="opacity-100 translate-y-0 sm:scale-100"
            leave="ease-in duration-200"
            leaveFrom="opacity-100 translate-y-0 sm:scale-100"
            leaveTo="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          >
            <div className="inline-block align-bottom bg-slate-800 rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
              <div className="hidden sm:block absolute top-0 right-0 pt-4 pr-4">
                <button
                  type="button"
                  className="bg-slate-800 rounded-md text-white hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-600"
                  onClick={() => handleClose()}
                >
                  <span className="sr-only">Close</span>
                  <span className="h-6 w-6 material-icons-round">close</span>
                </button>
              </div>
              <div className="sm:flex sm:items-start">
                <div
                  className={`${
                    type === "info" ? "bg-blue bg-opacity-30" : "bg-orange-100"
                  } mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full sm:mx-0 sm:h-10 sm:w-10`}
                >
                  <span
                    className={`${
                      type === "info" ? "text-blue" : "text-orange-500"
                    } material-icons-round`}
                  >
                    {type === "warning" ? "warning_amber" : "info"}
                  </span>
                </div>
                <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <Dialog.Title as="h3" className="text-lg leading-6 font-medium text-white">
                    {title}
                  </Dialog.Title>
                  <div className="mt-2">
                    <p className="text-sm text-white">{message}</p>
                  </div>
                </div>
              </div>
              <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                <button
                  type="button"
                  className={`${
                    type === "info" ? "bg-blue focus:ring-blue" : "bg-orange-500 hover:bg-orange-600 focus:ring-orange-500"
                  } w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 text-base font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm`}
                  onClick={() => {
                    handleConfirmation();
                    handleClose();
                  }}
                >
                  {confirmation}
                </button>
                <button
                  type="button"
                  className={`mt-3 w-full inline-flex justify-center rounded-md shadow-sm px-4 py-2 text-white text-base font-medium hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-600 sm:mt-0 sm:w-auto sm:text-sm`}
                  onClick={() => handleClose()}
                >
                  {cancel}
                </button>
              </div>
            </div>
          </Transition.Child>
        </div>
      </Dialog>
    </Transition.Root>
  );
}
